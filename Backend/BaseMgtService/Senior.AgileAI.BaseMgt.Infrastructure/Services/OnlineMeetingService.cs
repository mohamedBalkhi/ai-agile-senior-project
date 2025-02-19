using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Net.Http.Json;
using System.Text.Json;
using Polly.CircuitBreaker;
using Polly.Retry;
using Senior.AgileAI.BaseMgt.Infrastructure.Resilience;
using System.Text;
using System.Text.Json.Serialization;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class OnlineMeetingService : IOnlineMeetingService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OnlineMeetingService> _logger;
    private readonly IResiliencePolicy<OnlineMeetingService> _resiliencePolicy;
    private readonly JsonSerializerOptions _jsonOptions;

    public OnlineMeetingService(
        HttpClient httpClient,
        ILogger<OnlineMeetingService> logger,
        IResiliencePolicy<OnlineMeetingService> resiliencePolicy)
    {
        _httpClient = httpClient;
        _logger = logger;
        _resiliencePolicy = resiliencePolicy;
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };
    }

    public async Task<RoomResult> CreateRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Creating room: {RoomName}",
                operationId, roomName);

            var request = new RoomRequest(roomName);
            var jsonContent = JsonSerializer.Serialize(request, _jsonOptions);
            var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("/api/rooms", content, cancellationToken);
            
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<JsonElement>(_jsonOptions, cancellationToken);

            var roomResult = new RoomResult(
                result.GetProperty("sid").GetString()!,
                result.GetProperty("name").GetString()!,
                result.GetProperty("numParticipants").GetInt32(),
                result.GetProperty("creationTime").GetInt64(),
                result.GetProperty("activeRecording").GetBoolean()
            );

            _logger.LogInformation(
                "[{OperationId}] Room created successfully: {RoomName}, SID: {Sid}",
                operationId, roomResult.Name, roomResult.Sid);

            return roomResult;
        });
    }

    public async Task<bool> DeleteRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Deleting room: {RoomName}",
                operationId, roomName);

            var response = await _httpClient.DeleteAsync(
                $"/api/rooms/{roomName}", 
                cancellationToken);
                
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            _logger.LogInformation(
                "[{OperationId}] Room deleted successfully: {RoomName}",
                operationId, roomName);

            return true;
        });
    }

    public async Task<RoomResult?> GetRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Getting room: {RoomName}",
                operationId, roomName);

            var response = await _httpClient.GetAsync(
                $"/api/rooms/{roomName}", 
                cancellationToken);

            await LogResponseContent(response, operationId, cancellationToken);

            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                var error = await response.Content.ReadFromJsonAsync<JsonElement>(
                    _jsonOptions,
                    cancellationToken);

                if (error.TryGetProperty("message", out var message) && 
                    message.GetString() == "Room not found")
                {
                    _logger.LogInformation(
                        "[{OperationId}] Room not found: {RoomName}",
                        operationId, roomName);
                    return null;
                }
            }
            
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(
                _jsonOptions,
                cancellationToken);

            return new RoomResult(
                result.GetProperty("sid").GetString()!,
                result.GetProperty("name").GetString()!,
                result.GetProperty("numParticipants").GetInt32(),
                result.GetProperty("creationTime").GetInt64(),
                result.GetProperty("activeRecording").GetBoolean()
            );
        });
    }

    public async Task<string> StartRecordingAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Starting recording for room: {RoomName}",
                operationId, roomName);

            var response = await _httpClient.PostAsync(
                $"/api/rooms/{roomName}/recording/start", 
                null, 
                cancellationToken);
                
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(
                _jsonOptions,
                cancellationToken);
            
            var audioUrl = result.GetProperty("audioUrl").GetString() 
                ?? throw new InvalidOperationException("Audio URL not found in response");

            _logger.LogInformation(
                "[{OperationId}] Recording started successfully for room: {RoomName}",
                operationId, roomName);

            return audioUrl;
        });
    }

    public async Task<bool> StopRecordingAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Stopping recording for room: {RoomName}",
                operationId, roomName);

            var response = await _httpClient.PostAsync(
                $"/api/rooms/{roomName}/recording/stop", 
                null, 
                cancellationToken);
                
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();

            _logger.LogInformation(
                "[{OperationId}] Recording stopped successfully for room: {RoomName}",
                operationId, roomName);

            return true;
        });
    }

    public async Task<RecordingStatus> GetRecordingStatusAsync(string roomName, CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Getting recording status for room: {RoomName}",
                operationId, roomName);

            var response = await _httpClient.GetAsync(
                $"/api/rooms/{roomName}/recording/status", 
                cancellationToken);
                
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(
                _jsonOptions,
                cancellationToken);

            var status = new RecordingStatus(
                result.GetProperty("isRecording").GetBoolean(),
                result.GetProperty("recordingId").GetString(),
                result.GetProperty("status").GetString() ?? string.Empty,
                result.GetProperty("startedAt").ValueKind != JsonValueKind.Null ? 
                    DateTime.Parse(result.GetProperty("startedAt").GetString()!) : null,
                result.GetProperty("outputUrl").ValueKind != JsonValueKind.Null ?
                    result.GetProperty("outputUrl").GetString() : null
            );

            _logger.LogInformation(
                "[{OperationId}] Got recording status for room: {RoomName}, Status: {Status}",
                operationId, roomName, status.Status);

            return status;
        });
    }

    public async Task<string> GenerateTokenAsync(
        string roomName, 
        string identity, 
        Dictionary<string, string> metadata, 
        CancellationToken cancellationToken = default)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        
        return await _resiliencePolicy.ExecuteAsync(async () =>
        {
            _logger.LogInformation(
                "[{OperationId}] Generating token for room: {RoomName}, Identity: {Identity}",
                operationId, roomName, identity);

            var request = new TokenRequest(identity, metadata);
            var jsonContent = JsonSerializer.Serialize(request, _jsonOptions);
            var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(
                $"/api/rooms/{roomName}/token", 
                content,
                cancellationToken);
                
            await LogResponseContent(response, operationId, cancellationToken);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(
                _jsonOptions,
                cancellationToken);

            var token = result.GetProperty("token").GetString() 
                ?? throw new InvalidOperationException("Token not found in response");

            _logger.LogInformation(
                "[{OperationId}] Token generated successfully for room: {RoomName}, Identity: {Identity}",
                operationId, roomName, identity);

            return token;
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

    private record RoomRequest(string RoomName);
    private record TokenRequest(string Identity, Dictionary<string, string> Metadata);

    private record RecordingResponse
    {
        [JsonPropertyName("audioUrl")]
        public required string AudioUrl { get; init; }
    }

    private record TokenResponse
    {
        [JsonPropertyName("token")]
        public required string Token { get; init; }
    }

    private record RecordingStatusResponse
    {
        [JsonPropertyName("isRecording")]
        public required bool IsRecording { get; init; }
        
        [JsonPropertyName("recordingId")]
        public required string RecordingId { get; init; }
        
        [JsonPropertyName("status")]
        public required string Status { get; init; }
        
        [JsonPropertyName("startedAt")]
        public DateTime? StartedAt { get; init; }
        
        [JsonPropertyName("outputUrl")]
        public string? OutputUrl { get; init; }
    }
}