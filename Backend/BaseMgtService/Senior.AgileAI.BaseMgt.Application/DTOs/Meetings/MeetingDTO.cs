using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public record MeetingDTO
{
    public Guid Id { get; init; }
    public required string Title { get; init; }
    public required DateTime StartTime { get; init; }
    public required DateTime EndTime { get; init; }
    public required MeetingType Type { get; init; }
    public required MeetingStatus Status { get; init; }
    public required string CreatorName { get; init; }
    public required string TimeZoneId { get; init; }
    public int MemberCount { get; init; }
    public bool IsRecurring { get; init; }
    public bool IsRecurringInstance { get; init; }
    public Guid? OriginalMeetingId { get; init; }
    public RecurringMeetingPatternDTO? RecurringPattern { get; init; }
    public bool HasAudio { get; init; }

    public required string ProjectId { get; init; }
    public required string ProjectName { get; init; }
} 