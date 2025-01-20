using Microsoft.AspNetCore.Http;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public interface IAudioTranscodingService
{
    Task<Stream> TranscodeToM4AAsync(Stream inputStream, CancellationToken cancellationToken = default);
    Task<bool> RequiresTranscodingAsync(string mimeType, CancellationToken cancellationToken = default);
}
