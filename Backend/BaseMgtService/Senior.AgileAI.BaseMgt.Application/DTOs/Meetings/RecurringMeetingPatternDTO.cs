using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public record RecurringMeetingPatternDTO
{
    public required RecurrenceType RecurrenceType { get; init; }
    public required int Interval { get; init; }
    public required DateTime RecurringEndDate { get; init; }
    public DaysOfWeek? DaysOfWeek { get; init; }
} 