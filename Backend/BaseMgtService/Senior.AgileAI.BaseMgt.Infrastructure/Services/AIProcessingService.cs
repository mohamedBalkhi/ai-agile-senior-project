using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Domain.ValueObjects;
using Polly.CircuitBreaker;
using Polly.Retry;
using Senior.AgileAI.BaseMgt.Infrastructure.Resilience;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class AIProcessingService : IAIProcessingService
{
    private readonly HttpClient _httpClient;
    private readonly IAudioStorageService _audioStorage;
    private readonly ILogger<AIProcessingService> _logger;
    private readonly string _baseUrl;
    private readonly string _apiKey;
    private readonly IResiliencePolicy<AIProcessingService> _resiliencePolicy;
    private readonly JsonSerializerOptions _jsonOptions;

    public AIProcessingService(
        HttpClient httpClient,
        IAudioStorageService audioStorage,
        IConfiguration configuration,
        ILogger<AIProcessingService> logger,
        IResiliencePolicy<AIProcessingService> resiliencePolicy)
    {
        _httpClient = httpClient;
        _audioStorage = audioStorage;
        _logger = logger;
        _resiliencePolicy = resiliencePolicy;
        
        _baseUrl = configuration["AIProcessing:BaseUrl"] 
            ?? throw new InvalidOperationException("AI Processing BaseUrl not configured");
        _apiKey = "raghadDEDA200217";
            
        _httpClient.DefaultRequestHeaders.Add("x-api-key", _apiKey);

        _jsonOptions = new JsonSerializerOptions 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
            WriteIndented = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };
    }

    public async Task<string> SubmitAudioForProcessingAsync(string audioUrl, string mainLanguage, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        _logger.LogInformation(
            "Starting audio submission. OperationId: {OperationId}, AudioUrl: {AudioUrl}, Language: {Language}",
            operationId, audioUrl, mainLanguage);

        var presignedUrl = await _audioStorage.GetPreSignedUrlAsync(
            audioUrl, 
            TimeSpan.FromHours(12),
            cancellationToken);
        
        _logger.LogDebug("Generated presigned URL for audio file. Expires in 12 hours");

        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var request = new SubmitAudioRequest { AudioUrl = presignedUrl, MainLanguage = mainLanguage };
            var jsonContent = JsonSerializer.Serialize(request, _jsonOptions);
            
            _logger.LogDebug(
                "[{OperationId}] Request payload: {Payload}",
                operationId, jsonContent);

            var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync(
                $"{_baseUrl}/ai_processor/submit_audio/",
                content,
                cancellationToken);

            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<SubmitAudioResponse>(_jsonOptions, cancellationToken)
                ?? throw new AIProcessingException("Invalid response from AI service");

            _logger.LogInformation(
                "[{OperationId}] Audio successfully submitted. Token: {Token}",
                operationId,
                result.AudioToken);

            return result.AudioToken;
        });
    }

    public async Task<(bool isDone, string status)> GetProcessingStatusAsync(string processingToken, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        _logger.LogDebug(
            "[{OperationId}] Checking processing status for token: {Token}",
            operationId, processingToken);

        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var response = await _httpClient.GetAsync(
                $"{_baseUrl}/ai_processor/status/{processingToken}/",
                cancellationToken);

            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<ProcessingStatusResponse>(_jsonOptions, cancellationToken)
                ?? throw new AIProcessingException("Invalid response from AI service");

            _logger.LogInformation(
                "[{OperationId}] Status check - Token: {Token}, Done: {Done}, Status: {Status}",
                operationId, processingToken, result.Done, result.Status);

            return (result.Done, result.Status);
        });
    }

    public async Task<MeetingAIReport> GetProcessingReportAsync(string processingToken, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        _logger.LogInformation(
            "[{OperationId}] Retrieving processing report for token: {Token}",
            operationId, processingToken);

        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            var response = await _httpClient.GetAsync(
                $"{_baseUrl}/ai_processor/report/{processingToken}/",
                cancellationToken);

            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<ProcessingReportResponse>(_jsonOptions, cancellationToken)
                ?? throw new AIProcessingException("Invalid response from AI service");

            _logger.LogInformation(
                "[{OperationId}] Successfully retrieved report. TranscriptLength: {Length}, KeyPoints: {Points}",
                operationId,
                result.Transcript?.Length ?? 0,
                result.KeyPoints?.Count ?? 0);
        
            return MeetingAIReport.Create(
                result.Transcript ?? string.Empty,
                result.Summary ?? string.Empty,
                result.KeyPoints ?? new List<string>());
        });
    }

    private async Task LogResponseContent(
        HttpResponseMessage response, 
        string operationId,
        CancellationToken cancellationToken = default)
    {
        var content = await response.Content.ReadAsStringAsync(cancellationToken);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorSummary = content.Length > 100 ? 
                content[..100].Replace("\n", " ") + "..." : 
                content.Replace("\n", " ");

            _logger.LogError(
                "[{OperationId}] Request failed. Status: {StatusCode}, Error: {ErrorSummary}",
                operationId,
                response.StatusCode,
                errorSummary);

            _logger.LogDebug(
                "[{OperationId}] Request details: Method={Method}, URL={URL}, Headers={Headers}",
                operationId,
                response.RequestMessage?.Method,
                response.RequestMessage?.RequestUri,
                response.RequestMessage?.Headers != null 
                    ? string.Join(", ", response.RequestMessage.Headers.Select(h => $"{h.Key}={string.Join(",", h.Value)}"))
                    : string.Empty);
        }
        else
        {
            _logger.LogDebug(
                "[{OperationId}] Response content: {Content}",
                operationId,
                content);
        }
    }

    private record SubmitAudioRequest
    {
        [JsonPropertyName("audio_url")]
        public required string AudioUrl { get; init; }

        [JsonPropertyName("main_language")]
        public required string MainLanguage { get; init; }
    }

    private record SubmitAudioResponse
    {
        [JsonPropertyName("audio_token")]
        public required string AudioToken { get; init; }
    }

    private record ProcessingStatusResponse
    {
        [JsonPropertyName("done")]
        public required bool Done { get; init; }
        
        [JsonPropertyName("status")]
        public required string Status { get; init; }
    }

    private record ProcessingReportResponse
    {
        [JsonPropertyName("transcript")]
        public required string Transcript { get; init; }
        
        [JsonPropertyName("summary")]
        public required string Summary { get; init; }
        
        [JsonPropertyName("key_points")]
        public required List<string> KeyPoints { get; init; }
        
        [JsonPropertyName("main_language")]
        public string? MainLanguage { get; init; }
    }
}
