using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Diagnostics;

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

            // Configure FFmpeg process
            var startInfo = new ProcessStartInfo
            {
                FileName = "ffmpeg",
                Arguments = $"-i \"{tempInputFile}\" -c:a aac -b:a 256k \"{tempOutputFile}\"",
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            // Run FFmpeg
            using (var process = new Process { StartInfo = startInfo })
            {
                process.Start();
                var error = await process.StandardError.ReadToEndAsync();
                await process.WaitForExitAsync(cancellationToken);

                if (process.ExitCode != 0)
                {
                    throw new Exception($"FFmpeg transcoding failed: {error}");
                }
            }

            // Return the transcoded file as a stream
            return File.OpenRead(tempOutputFile);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during audio transcoding");
            throw;
        }
        finally
        {
            // Cleanup temp files
            if (File.Exists(tempInputFile))
                File.Delete(tempInputFile);
        }
    }

    public Task<bool> RequiresTranscodingAsync(string mimeType, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(!_m4aCompatibleMimeTypes.Contains(mimeType.ToLower()));
    }
}
