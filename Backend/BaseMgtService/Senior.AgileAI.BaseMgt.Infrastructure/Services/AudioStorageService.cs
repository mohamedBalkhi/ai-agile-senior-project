using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Transfer;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Web;
using Senior.AgileAI.BaseMgt.Infrastructure.Resilience;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class AudioStorageService : IAudioStorageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName;
    private readonly ILogger<AudioStorageService> _logger;
    private readonly IAudioTranscodingService _transcodingService;
    private readonly IResiliencePolicy<AudioStorageService> _resiliencePolicy;
    private readonly string[] _allowedExtensions = { ".mp3", ".wav", ".m4a", ".opus" };
    private readonly long _maxFileSizeBytes = 500 * 1024 * 1024; // 500MB
    private readonly string[] _allowedMimeTypes = { 
        "audio/mpeg", 
        "audio/wav", 
        "audio/wave", 
        "audio/x-wav", 
        "audio/mp4", 
        "audio/x-m4a", 
        "audio/x-mp3", 
        "audio/basic",
        "audio/opus",
        "audio/ogg",
        "application/octet-stream" 
    };
    private readonly int _uploadTimeoutSeconds = 300; // 5 minutes

    public AudioStorageService(
        IConfiguration configuration,
        IAmazonS3 s3Client,
        ILogger<AudioStorageService> logger,
        IAudioTranscodingService transcodingService,
        IResiliencePolicy<AudioStorageService> resiliencePolicy)
    {
        _s3Client = s3Client;
        _bucketName = configuration["AWS:BucketName"] 
            ?? throw new ArgumentNullException("AWS:BucketName configuration is missing");
        _logger = logger;
        _transcodingService = transcodingService;
        _resiliencePolicy = resiliencePolicy;
    }

    public async Task<string> UploadAudioAsync(
        Guid meetingId, 
        IFormFile audioFile,
        CancellationToken cancellationToken = default)
    {
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            try
            {
                using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
                timeoutCts.CancelAfter(TimeSpan.FromSeconds(_uploadTimeoutSeconds));

                ValidateAudioFile(audioFile, timeoutCts.Token);

                var fileExtension = Path.GetExtension(audioFile.FileName).ToLowerInvariant();
                var fileName = $"meetings/{meetingId}/audio_{DateTime.UtcNow:yyyyMMddHHmmss}{fileExtension}";
                
                using var stream = audioFile.OpenReadStream();
                Stream uploadStream = stream;
                
                // Check if transcoding is needed
                if (await _transcodingService.RequiresTranscodingAsync(audioFile.ContentType, timeoutCts.Token))
                {
                    _logger.LogInformation("Transcoding audio file to M4A format");
                    uploadStream = await _transcodingService.TranscodeToM4AAsync(stream, timeoutCts.Token);
                    fileName = Path.ChangeExtension(fileName, ".m4a");
                }

                var uploadRequest = new TransferUtilityUploadRequest
                {
                    InputStream = uploadStream,
                    BucketName = _bucketName,
                    Key = fileName,
                    ContentType = GetContentType(Path.GetExtension(fileName))
                };

                var fileTransferUtility = new TransferUtility(_s3Client);
                await fileTransferUtility.UploadAsync(uploadRequest, timeoutCts.Token);

                return $"https://{_bucketName}.s3.amazonaws.com/{fileName}";
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning("Upload operation was cancelled by the caller");
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to upload audio file for meeting {MeetingId}", meetingId);
                throw;
            }
        });
    }

    public async Task<Stream> GetAudioAsync(string audioUrl, CancellationToken cancellationToken = default)
    {
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var key = GetKeyFromUrl(audioUrl);
            var request = new GetObjectRequest
            {
                BucketName = _bucketName,
                Key = key
            };

            var response = await _s3Client.GetObjectAsync(request, cancellationToken);
            
            // Create a MemoryStream to store the file content
            var memoryStream = new MemoryStream();
            await response.ResponseStream.CopyToAsync(memoryStream, cancellationToken);
            memoryStream.Position = 0;
            
            return memoryStream;
        });
    }

    public async Task DeleteAudioAsync(string audioUrl, CancellationToken cancellationToken = default)
    {
        await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var key = GetKeyFromUrl(audioUrl);
            var request = new DeleteObjectRequest
            {
                BucketName = _bucketName,
                Key = key
            };

            await _s3Client.DeleteObjectAsync(request, cancellationToken);
            _logger.LogInformation("Audio file deleted successfully: {Url}", audioUrl);
        });
    }

    public bool ValidateAudioFile(
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            _logger.LogWarning("Audio file is null or empty");
            return false;
        }

        if (file.Length > _maxFileSizeBytes)
        {
            _logger.LogWarning(
                "Audio file size {Size} exceeds maximum allowed size {MaxSize}",
                file.Length, _maxFileSizeBytes);
            return false;
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        // Add more detailed logging
        _logger.LogInformation(
            "Validating audio file: Extension={Extension}, ContentType={ContentType}, Size={Size}",
            extension, file.ContentType, file.Length);


        // Special handling for octet-stream
        if (file.ContentType.ToLowerInvariant() == "application/octet-stream")
        {
            // In this case, we rely more heavily on the file extension
            if (!_allowedExtensions.Contains(extension))
            {
                _logger.LogWarning(
                    "Invalid audio file extension for octet-stream: {Extension}. Allowed extensions: {AllowedExtensions}",
                        extension, string.Join(", ", _allowedExtensions));
                return false;
            }
            return true;
        }

        // Check if the content type contains any of the allowed types (more flexible check)
        var isValidContentType = _allowedMimeTypes.Any(mime =>
            file.ContentType.ToLowerInvariant().Contains(mime.ToLowerInvariant()));

        if (!isValidContentType)
        {
            _logger.LogWarning(
                "Invalid audio file content type: {ContentType}. Allowed types: {AllowedTypes}",
                file.ContentType, string.Join(", ", _allowedMimeTypes));
            return false;
        }

        if (!_allowedExtensions.Contains(extension))
        {
            _logger.LogWarning(
                "Invalid audio file extension: {Extension}. Allowed extensions: {AllowedExtensions}",
                extension, string.Join(", ", _allowedExtensions));
            return false;
        }

        return true;
    }

    public async Task<AudioMetadata> GetAudioMetadataAsync(
        string audioUrl, 
        CancellationToken cancellationToken = default)
    {
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var key = GetKeyFromUrl(audioUrl);
            var request = new GetObjectMetadataRequest
            {
                BucketName = _bucketName,
                Key = key
            };

            var metadata = await _s3Client.GetObjectMetadataAsync(request, cancellationToken);

            return new AudioMetadata
            {
                SizeInBytes = metadata.ContentLength,
                Format = Path.GetExtension(key).TrimStart('.'),
                MimeType = metadata.Headers.ContentType,
                UploadedAt = metadata.LastModified,
                Duration = TimeSpan.Zero // Would need additional processing to get actual duration
            };
        });
    }

    public async Task<string> GetPreSignedUrlAsync(
        string audioUrl, 
        TimeSpan expiration,
        CancellationToken cancellationToken = default)
    {
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var key = GetKeyFromUrl(audioUrl);
            var request = new GetPreSignedUrlRequest
            {
                BucketName = _bucketName,
                Key = key,
                Expires = DateTime.UtcNow.Add(expiration),
                ResponseHeaderOverrides = new ResponseHeaderOverrides
                {
                    ContentType = GetContentType(key),
                    ContentDisposition = $"inline; filename=\"{Path.GetFileName(key)}\""
                }
            };

            return await _s3Client.GetPreSignedURLAsync(request);
        });
    }

    public async Task<string> TranscodeToM4AAsync(string sourceUrl, CancellationToken cancellationToken = default)
    {
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            // Download the source file
            var sourceStream = await GetAudioAsync(sourceUrl, cancellationToken);
            
            // Transcode to M4A
            var transcodedStream = await _transcodingService.TranscodeToM4AAsync(sourceStream, cancellationToken);
            
            // Generate new filename
            var newFileName = Path.ChangeExtension(sourceUrl, ".m4a");
            
            // Upload transcoded file
            var uploadRequest = new TransferUtilityUploadRequest
            {
                InputStream = transcodedStream,
                BucketName = _bucketName,
                Key = newFileName,
                ContentType = "audio/x-m4a"
            };

            var fileTransferUtility = new TransferUtility(_s3Client);
            await fileTransferUtility.UploadAsync(uploadRequest, cancellationToken);
            
            // Delete the original file
            await DeleteAudioAsync(sourceUrl, cancellationToken);
            
            return newFileName;
        });
    }

    private string GetContentType(string key)
    {
        var extension = Path.GetExtension(key).ToLowerInvariant();
        return extension switch
        {
            ".mp3" => "audio/mpeg",
            ".wav" => "audio/wav",
            ".m4a" => "audio/mp4",
            ".opus" => "audio/opus",
            _ => "application/octet-stream"
        };
    }

    private string GetKeyFromUrl(string audioUrl)
    {
        if (string.IsNullOrEmpty(audioUrl))
            throw new ArgumentException("Audio URL cannot be null or empty");

        try
        {
            var uri = new Uri(audioUrl);
            return HttpUtility.UrlDecode(uri.LocalPath.TrimStart('/'));
        }
        catch (UriFormatException ex)
        {
            throw new ArgumentException("Invalid audio URL format", nameof(audioUrl), ex);
        }
    }
} 