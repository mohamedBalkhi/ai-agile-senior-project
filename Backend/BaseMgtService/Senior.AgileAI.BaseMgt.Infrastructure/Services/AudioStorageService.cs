using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Transfer;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Web;
using Polly;
using Polly.Retry;
using Senior.AgileAI.BaseMgt.Infrastructure.Extensions;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class AudioStorageService : IAudioStorageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName;
    private readonly ILogger<AudioStorageService> _logger;
    private readonly IAudioTranscodingService _transcodingService;
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
    private readonly AsyncRetryPolicy _retryPolicy;

    public AudioStorageService(
        IConfiguration configuration,
        IAmazonS3 s3Client,
        ILogger<AudioStorageService> logger,
        IAudioTranscodingService transcodingService)
    {
        _s3Client = s3Client;
        _bucketName = configuration["AWS:BucketName"] 
            ?? throw new ArgumentNullException("AWS:BucketName configuration is missing");
        _logger = logger;
        _transcodingService = transcodingService;

        // Configure retry policy
        _retryPolicy = Policy
            .Handle<AmazonS3Exception>(ex => ex.IsTransient())
            .Or<TimeoutException>()
            .WaitAndRetryAsync(3, retryAttempt => 
                TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (exception, timeSpan, retryCount, context) =>
                {
                    _logger.LogWarning(exception, 
                        "Retry {RetryCount} after {Delay}s delay due to {Message}", 
                        retryCount, timeSpan.TotalSeconds, exception.Message);
                });
    }

    public async Task<string> UploadAudioAsync(
        Guid meetingId, 
        IFormFile audioFile,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await ValidateAudioFileAsync(audioFile, cancellationToken);

            var fileExtension = Path.GetExtension(audioFile.FileName).ToLowerInvariant();
            var fileName = $"meetings/{meetingId}/audio_{DateTime.UtcNow:yyyyMMddHHmmss}{fileExtension}";
            
            using var stream = audioFile.OpenReadStream();
            Stream uploadStream = stream;
            
            // Check if transcoding is needed
            if (await _transcodingService.RequiresTranscodingAsync(audioFile.ContentType, cancellationToken))
            {
                _logger.LogInformation("Transcoding audio file to M4A format");
                uploadStream = await _transcodingService.TranscodeToM4AAsync(stream, cancellationToken);
                fileName = Path.ChangeExtension(fileName, ".m4a");
            }

            var uploadRequest = new TransferUtilityUploadRequest
            {
                InputStream = uploadStream,
                BucketName = _bucketName,
                Key = fileName,
                ContentType = "audio/x-m4a"
            };
            var fileTransferUtility = new TransferUtility(_s3Client);
            await fileTransferUtility.UploadAsync(uploadRequest, cancellationToken);

            return $"https://{_bucketName}.s3.amazonaws.com/{fileName}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading audio file for meeting {MeetingId}", meetingId);
            throw;
        }
    }

    public async Task<Stream> GetAudioAsync(string audioUrl, CancellationToken cancellationToken = default)
    {
        try
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
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger.LogWarning("Audio file not found: {Url}", audioUrl);
            throw new NotFoundException("Audio file not found");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving audio file from {Url}", audioUrl);
            throw new AudioStorageException("Failed to retrieve audio file", ex);
        }
    }

    public async Task DeleteAudioAsync(string audioUrl, CancellationToken cancellationToken = default)
    {
        try
        {
            var key = GetKeyFromUrl(audioUrl);
            var request = new DeleteObjectRequest
            {
                BucketName = _bucketName,
                Key = key
            };

            await _s3Client.DeleteObjectAsync(request, cancellationToken);
            _logger.LogInformation("Audio file deleted successfully: {Url}", audioUrl);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting audio file: {Url}", audioUrl);
            throw new AudioStorageException("Failed to delete audio file", ex);
        }
    }

    public async Task<bool> ValidateAudioFileAsync(
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
        try
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
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            throw new NotFoundException("Audio file not found");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting audio metadata from {Url}", audioUrl);
            throw new AudioStorageException("Failed to get audio metadata", ex);
        }
    }

    public async Task<string> GetPreSignedUrlAsync(
        string audioUrl, 
        TimeSpan expiration,
        CancellationToken cancellationToken = default)
    {
        try
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

            return _s3Client.GetPreSignedURL(request);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating pre-signed URL for audio file: {Url}", audioUrl);
            throw new AudioStorageException("Failed to generate audio access URL", ex);
        }
    }

    public async Task<string> TranscodeToM4AAsync(string sourceUrl, CancellationToken cancellationToken = default)
    {
        try
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
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error transcoding audio file {SourceUrl}", sourceUrl);
            throw;
        }
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