using Senior.AgileAI.BaseMgt.Domain.ValueObjects;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public interface IAIProcessingService
{
    /// <summary>
    /// Submits an audio file for AI processing
    /// </summary>
    /// <param name="audioUrl">The S3 URL of the audio file</param>
    /// <param name="mainLanguage">The main language of the audio file</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Processing token for tracking status</returns>
    Task<string> SubmitAudioForProcessingAsync(string audioUrl, string mainLanguage, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets the current processing status
    /// </summary>
    /// <param name="processingToken">Token received from submission</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Tuple of (isDone, status)</returns>
    Task<(bool isDone, string status)> GetProcessingStatusAsync(string processingToken, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets the processing report when complete
    /// </summary>
    /// <param name="processingToken">Token received from submission</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>AI processing report</returns>
    Task<MeetingAIReport> GetProcessingReportAsync(string processingToken, CancellationToken cancellationToken = default);
}
