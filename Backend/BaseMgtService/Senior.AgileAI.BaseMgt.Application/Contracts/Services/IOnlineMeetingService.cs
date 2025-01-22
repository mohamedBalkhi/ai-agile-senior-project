using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public interface IOnlineMeetingService
{
    Task<RoomResult> CreateRoomAsync(string roomName, CancellationToken cancellationToken = default);
    Task<bool> DeleteRoomAsync(string roomName, CancellationToken cancellationToken = default);
    Task<RoomResult> GetRoomAsync(string roomName, CancellationToken cancellationToken = default);
    Task<string> StartRecordingAsync(string roomName, CancellationToken cancellationToken = default);
    Task<bool> StopRecordingAsync(string roomName, CancellationToken cancellationToken = default);
    Task<RecordingStatus> GetRecordingStatusAsync(string roomName, CancellationToken cancellationToken = default);
    Task<string> GenerateTokenAsync(string roomName, string identity, Dictionary<string, string> metadata, CancellationToken cancellationToken = default);
}

public record RoomResult(
    string Sid,
    string Name,
    int NumParticipants,
    long CreationTime,
    bool ActiveRecording
);

public record RecordingStatus(
    bool IsRecording,
    string? RecordingId,
    string Status,
    DateTime? StartedAt,
    string? OutputUrl
); 