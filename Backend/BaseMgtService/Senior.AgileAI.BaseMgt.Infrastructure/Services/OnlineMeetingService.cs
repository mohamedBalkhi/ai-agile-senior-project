using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Models;
using System.Net.Http.Json;
using System.Text.Json;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class OnlineMeetingService : IOnlineMeetingService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OnlineMeetingService> _logger;
    private readonly string _meetingServiceUrl;

    public OnlineMeetingService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<OnlineMeetingService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        
        _meetingServiceUrl = configuration["MeetingService:Url"] ?? throw new ArgumentNullException("MeetingService:Url");
        _httpClient.BaseAddress = new Uri(_meetingServiceUrl);
    }

    public async Task<RoomResult> CreateRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync($"/api/rooms", new StringContent(
                JsonSerializer.Serialize(new { roomName }),
                System.Text.Encoding.UTF8,
                "application/json"
            ), cancellationToken);

            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            return new RoomResult(
                result.GetProperty("sid").GetString()!,
                result.GetProperty("name").GetString()!,
                result.GetProperty("numParticipants").GetInt32(),
                result.GetProperty("creationTime").GetInt64(),
                result.GetProperty("activeRecording").GetBoolean()
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<bool> DeleteRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"/api/rooms/{roomName}", cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<RoomResult> GetRoomAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"/api/rooms/{roomName}", cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);

            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                var error = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
                if (error.TryGetProperty("message", out var message) && 
                    message.GetString() == "Room not found")
                {
                    return null;
                }
            }
            
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            return new RoomResult(
                result.GetProperty("sid").GetString()!,
                result.GetProperty("name").GetString()!,
                result.GetProperty("numParticipants").GetInt32(),
                result.GetProperty("creationTime").GetInt64(),
                result.GetProperty("activeRecording").GetBoolean()
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<string> StartRecordingAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync($"/api/rooms/{roomName}/recording/start", null, cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            
            // // Handle case where recordingId property doesn't exist
            // if (result.TryGetProperty("recordingId", out var recordingIdElement))
            // {
            //     return recordingIdElement.GetString()!;
            // }
            // else if (result.TryGetProperty("egressId", out var egressIdElement)) 
            // {
            //     return egressIdElement.GetString()!;
            // }
            return result.GetProperty("audioUrl").GetString()!;
            
            throw new InvalidOperationException("Recording ID not found in response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to start recording for room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<bool> StopRecordingAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync($"/api/rooms/{roomName}/recording/stop", null, cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to stop recording for room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<RecordingStatus> GetRecordingStatusAsync(string roomName, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"/api/rooms/{roomName}/recording/status", cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            return new RecordingStatus(
                result.GetProperty("isRecording").GetBoolean(),
                result.GetProperty("recordingId").GetString(),
                result.GetProperty("status").GetString(),
                result.GetProperty("startedAt").ValueKind != JsonValueKind.Null ? 
                    DateTime.Parse(result.GetProperty("startedAt").GetString()!) : null,
                result.GetProperty("outputUrl").ValueKind != JsonValueKind.Null ?
                    result.GetProperty("outputUrl").GetString() : null
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get recording status for room {RoomName}", roomName);
            throw;
        }
    }

    public async Task<string> GenerateTokenAsync(string roomName, string identity, Dictionary<string, string> metadata, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync($"/api/rooms/{roomName}/token", new StringContent(
                JsonSerializer.Serialize(new { identity, metadata }),
                System.Text.Encoding.UTF8,
                "application/json"
            ), cancellationToken);

            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("Got response from meeting service: {Response}", responseContent);
            response.EnsureSuccessStatusCode();
            
            var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            return result.GetProperty("token").GetString()!;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate token for room {RoomName} and identity {Identity}", roomName, identity);
            throw;
        }
    }
}