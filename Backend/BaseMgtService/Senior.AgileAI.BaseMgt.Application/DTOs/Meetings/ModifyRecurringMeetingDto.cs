using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public class ModifyRecurringMeetingDto
{
    public required bool ApplyToSeries { get; init; }
    public string? Title { get; init; }
    public string? Goal { get; init; }
    public MeetingLanguage? Language { get; init; }
    public DateTime? StartTime { get; init; }
    public DateTime? EndTime { get; init; }
    public string? TimeZone { get; init; }
    public string? Location { get; init; }
    public DateTime? ReminderTime { get; init; }
    public MeetingStatus? Status { get; init; }
    public List<Guid>? AddMembers { get; init; }
    public List<Guid>? RemoveMembers { get; init; }
} 