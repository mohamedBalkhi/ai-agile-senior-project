using System.Net.Http;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Domain.ValueObjects;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class AIProcessingService : IAIProcessingService
{
    private readonly HttpClient _httpClient;
    private readonly IAudioStorageService _audioStorage;
    private readonly ILogger<AIProcessingService> _logger;
    private readonly string _baseUrl;
    private readonly string _apiKey;

    public AIProcessingService(
        HttpClient httpClient,
        IAudioStorageService audioStorage,
        IConfiguration configuration,
        ILogger<AIProcessingService> logger)
    {
        _httpClient = httpClient;
        _audioStorage = audioStorage;
        _logger = logger;
        _baseUrl = configuration["AIProcessing:BaseUrl"] 
            ?? throw new InvalidOperationException("AI Processing BaseUrl not configured");
        _apiKey = configuration["AIProcessing:ApiKey"]
            ?? throw new InvalidOperationException("AI Processing ApiKey not configured");
            
        _httpClient.DefaultRequestHeaders.Add("X-API-Key", _apiKey);
    }

    public async Task<string> SubmitAudioForProcessingAsync(string audioUrl, string mainLanguage, CancellationToken cancellationToken = default)
    {
        try
        {
            // Get pre-signed URL with 12-hour expiry
            var presignedUrl = await _audioStorage.GetPreSignedUrlAsync(
                audioUrl, 
                TimeSpan.FromHours(12),
                cancellationToken);

            var request = new SubmitAudioRequest { AudioUrl = presignedUrl, MainLanguage = mainLanguage };
            
            // Serialize with proper options
            var jsonOptions = new JsonSerializerOptions 
            { 
                PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
                WriteIndented = true 
            };
            var jsonContent = JsonSerializer.Serialize(request, jsonOptions);
            _logger.LogInformation("Sending request payload: {Payload}", jsonContent);

            // Create request with explicit content type
            var content = new StringContent(
                jsonContent,
                Encoding.UTF8,
                "application/json"
            );

            var response = await _httpClient.PostAsync(
                $"{_baseUrl}/ai_processor/submit_audio/",
                content,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("AI service returned {StatusCode}: {Error}", 
                    response.StatusCode, errorContent);
                
                // Log request details for debugging
                _logger.LogError("Request details: Method={Method}, URL={URL}, Headers={Headers}, Content={Content}",
                    response.RequestMessage?.Method,
                    response.RequestMessage?.RequestUri,
                    string.Join(", ", response.RequestMessage?.Headers.Select(h => $"{h.Key}={string.Join(",", h.Value)}")),
                    jsonContent);
            }

            response.EnsureSuccessStatusCode();

            var resultContent = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<SubmitAudioResponse>(
                resultContent,
                jsonOptions);

            return result?.AudioToken 
                ?? throw new AIProcessingException("No audio token received from AI service");
        }
        catch (Exception ex) when (ex is not AIProcessingException)
        {
            _logger.LogError(ex, "Failed to submit audio for processing: {Url}", audioUrl);
            throw new AIProcessingException("Failed to submit audio for processing", ex);
        }
    }

    public async Task<(bool isDone, string status)> GetProcessingStatusAsync(
        string processingToken,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"{_baseUrl}/ai_processor/status/{processingToken}/",
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("AI service returned {StatusCode}: {Error}", 
                    response.StatusCode, errorContent);
            }

            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<ProcessingStatusResponse>(
                cancellationToken: cancellationToken);

            if (result == null)
                throw new AIProcessingException("Invalid response from AI service");

            return (result.Done, result.Status);
        }
        catch (Exception ex) when (ex is not AIProcessingException)
        {
            _logger.LogError(ex, "Failed to get processing status: {Token}", processingToken);
            throw new AIProcessingException("Failed to get processing status", ex);
        }
    }

    public async Task<MeetingAIReport> GetProcessingReportAsync(
        string processingToken,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"{_baseUrl}/ai_processor/report/{processingToken}/",
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("AI service returned {StatusCode}: {Error}", 
                    response.StatusCode, errorContent);
            }

            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<ProcessingReportResponse>(
                cancellationToken: cancellationToken);
            _logger.LogInformation("Processing report: {Result}", result);
            if (result == null)
                throw new AIProcessingException("Invalid response from AI service");

            return MeetingAIReport.Create(
                result.Transcript,
                result.Summary,
                result.KeyPoints,
                result.MainLanguage ?? "en");
        }
        catch (Exception ex) when (ex is not AIProcessingException)
        {
            _logger.LogError(ex, "Failed to get processing report: {Token}", processingToken);
            throw new AIProcessingException("Failed to get processing report", ex);
        }
    }

    private record SubmitAudioResponse(string AudioToken);
    private record ProcessingStatusResponse(bool Done, string Status);
    private record ProcessingReportResponse(
        string Transcript,
        string Summary,
        [property : JsonPropertyName("key_points")]
        List<string> KeyPoints,
        [property : JsonPropertyName("main_language")]
        string? MainLanguage);

    public class SubmitAudioRequest
    {
        [JsonPropertyName("audio_url")]
        public required string AudioUrl { get; set; }

        [JsonPropertyName("main_language")]
        public required string MainLanguage { get; set; }
    }
}
