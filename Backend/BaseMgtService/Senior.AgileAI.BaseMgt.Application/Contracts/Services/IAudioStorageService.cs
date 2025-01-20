using Microsoft.AspNetCore.Http;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public interface IAudioStorageService
{
    Task<string> UploadAudioAsync(Guid meetingId, IFormFile audioFile, CancellationToken cancellationToken = default);
    Task<Stream> GetAudioAsync(string audioUrl, CancellationToken cancellationToken = default);
    Task DeleteAudioAsync(string audioUrl, CancellationToken cancellationToken = default);
    Task<bool> ValidateAudioFileAsync(IFormFile file, CancellationToken cancellationToken = default);
    Task<AudioMetadata> GetAudioMetadataAsync(string audioUrl, CancellationToken cancellationToken = default);
    Task<string> GetPreSignedUrlAsync(string audioUrl, TimeSpan expiration, CancellationToken cancellationToken = default);
    Task<string> TranscodeToM4AAsync(string sourceUrl, CancellationToken cancellationToken = default);
}

public record AudioMetadata
{
    public required long SizeInBytes { get; init; }
    public required TimeSpan Duration { get; init; }
    public required string Format { get; init; }
    public required string MimeType { get; init; }
    public required DateTime UploadedAt { get; init; }
}