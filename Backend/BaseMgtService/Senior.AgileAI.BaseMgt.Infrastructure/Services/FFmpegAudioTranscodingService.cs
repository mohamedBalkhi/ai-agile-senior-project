using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Diagnostics;
using System.Text;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class FFmpegAudioTranscodingService : IAudioTranscodingService
{
    private readonly ILogger<FFmpegAudioTranscodingService> _logger;
    private readonly string[] _m4aCompatibleMimeTypes = new[] 
    { 
        "audio/mp4", 
        "audio/x-m4a" 
    };

    public FFmpegAudioTranscodingService(ILogger<FFmpegAudioTranscodingService> logger)
    {
        _logger = logger;
    }

    public async Task<Stream> TranscodeToM4AAsync(Stream inputStream, CancellationToken cancellationToken = default)
    {
        var tempInputFile = Path.GetTempFileName();
        var tempOutputFile = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.m4a");

        try
        {
            // Save input stream to temp file
            using (var fileStream = File.Create(tempInputFile))
            {
                await inputStream.CopyToAsync(fileStream, cancellationToken);
            }

            // Configure FFmpeg process with improved arguments
            var startInfo = new ProcessStartInfo
            {
                FileName = "ffmpeg",
                // Key changes in the arguments:
                // 1. -vn to ignore video stream
                // 2. -map_metadata 0 to copy metadata
                // 3. Specific AAC encoder settings for better quality
                // 4. -movflags +faststart for better streaming
                Arguments = $"-i \"{tempInputFile}\" -vn -map_metadata 0 -c:a aac -b:a 256k -ar 44100 -movflags +faststart \"{tempOutputFile}\"",
                RedirectStandardError = true,
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            // Run FFmpeg with better error handling
            using (var process = new Process { StartInfo = startInfo })
            {
                var outputBuilder = new StringBuilder();
                var errorBuilder = new StringBuilder();

                process.OutputDataReceived += (sender, e) => 
                {
                    if (e.Data != null)
                    {
                        outputBuilder.AppendLine(e.Data);
                        _logger.LogDebug("FFmpeg: {Output}", e.Data);
                    }
                };

                process.ErrorDataReceived += (sender, e) => 
                {
                    if (e.Data != null)
                    {
                        errorBuilder.AppendLine(e.Data);
                        _logger.LogDebug("FFmpeg Error: {Error}", e.Data);
                    }
                };

                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                await process.WaitForExitAsync(cancellationToken);

                if (process.ExitCode != 0)
                {
                    var error = errorBuilder.ToString();
                    _logger.LogError("FFmpeg transcoding failed with exit code {ExitCode}. Error: {Error}", 
                        process.ExitCode, error);
                    throw new Exception($"FFmpeg transcoding failed with exit code {process.ExitCode}: {error}");
                }

                // Verify the output file exists and has content
                if (!File.Exists(tempOutputFile) || new FileInfo(tempOutputFile).Length == 0)
                {
                    throw new Exception("FFmpeg transcoding failed: Output file is missing or empty");
                }

                return File.OpenRead(tempOutputFile);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during audio transcoding");
            throw;
        }
        finally
        {
            try
            {
                // Cleanup temp files
                if (File.Exists(tempInputFile))
                    File.Delete(tempInputFile);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to cleanup temporary input file");
            }
        }
    }

    public Task<bool> RequiresTranscodingAsync(string mimeType, CancellationToken cancellationToken = default)
    {
        // Normalize the MIME type
        var normalizedMimeType = mimeType.ToLower().Trim();
        
        // Check if it's already in a compatible format
        if (_m4aCompatibleMimeTypes.Contains(normalizedMimeType))
        {
            return Task.FromResult(false);
        }

        // Always transcode these formats
        var formatsRequiringTranscoding = new[]
        {
            "audio/mpeg",
            "audio/mp3",
            "audio/wav",
            "audio/wave",
            "audio/x-wav",
            "audio/opus",
            "audio/ogg",
            "application/octet-stream"  // Usually indicates MP3 or other audio files
        };

        return Task.FromResult(formatsRequiringTranscoding.Contains(normalizedMimeType));
    }
}
