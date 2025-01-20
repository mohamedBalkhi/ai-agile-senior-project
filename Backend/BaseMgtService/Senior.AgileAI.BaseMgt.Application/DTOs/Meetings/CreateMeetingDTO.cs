using Senior.AgileAI.BaseMgt.Domain.Enums;
using Microsoft.AspNetCore.Http;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public record CreateMeetingDTO
{
    public required string Title { get; init; }
    public string? Goal { get; init; }
    public required MeetingLanguage Language { get; init; }
    public required MeetingType Type { get; init; }
    public required DateTime StartTime { get; init; }
    public required DateTime EndTime { get; init; }
    public required string TimeZone { get; init; }
    public required Guid ProjectId { get; init; }
    public List<Guid> MemberIds { get; init; } = new();
    public string? Location { get; init; }
    public DateTime? ReminderTime { get; init; }
    
    // For Done meetings
    public IFormFile? AudioFile { get; init; }  // Optional during creation
    
    // Recurring meeting properties
    public bool IsRecurring { get; init; }
    public RecurringMeetingPatternDTO? RecurringPattern { get; init; }
} 