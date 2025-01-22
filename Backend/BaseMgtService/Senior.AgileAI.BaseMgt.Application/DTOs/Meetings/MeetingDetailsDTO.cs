using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public record MeetingDetailsDTO
{
    public Guid Id { get; init; }
    public required string Title { get; init; }
    public required string Goal { get; init; }
    public required MeetingLanguage Language { get; init; }
    public required MeetingType Type { get; init; }
    public required DateTime StartTime { get; init; }
    public required DateTime EndTime { get; init; }
    public required string TimeZoneId { get; init; }
    public required TimeZoneDTO TimeZone { get; init; }
    public string? Location { get; init; }
    public string? MeetingUrl { get; init; }
    public string? AudioUrl { get; init; }
    
    // Online Meeting Properties
    public string? LiveKitRoomSid { get; init; }
    public string? LiveKitRoomName { get; init; }
    public OnlineMeetingStatus OnlineMeetingStatus { get; init; }
    public DateTime? OnlineMeetingStartedAt { get; init; }
    public DateTime? OnlineMeetingEndedAt { get; init; }
    
    public DateTime? ReminderTime { get; init; }
    public required MeetingStatus Status { get; init; }
    public MeetingMemberDTO? Creator { get; init; }
    public List<MeetingMemberDTO> Members { get; init; } = new();
    public bool IsRecurring { get; init; }
    public bool IsRecurringInstance { get; init; }
    public Guid? OriginalMeetingId { get; init; }
    public RecurringMeetingPatternDTO? RecurringPattern { get; init; }
    public required string ProjectId { get; init; }
    public required string ProjectName { get; init; }
}

public record MeetingMemberDTO
{
    public required Guid MemberId { get; init; }
    public required string MemberName { get; init; }
    public required bool HasConfirmed { get; init; }
    public required Guid UserId { get; init; }
    public required string Email { get; init; }
    public required Guid OrgMemberId { get; init; }
} 
