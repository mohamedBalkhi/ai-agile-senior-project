using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;

public record CreateCalendarSubscriptionDTO
{
    public required CalendarFeedType FeedType { get; init; }
    public Guid? ProjectId { get; init; }
    public Guid? RecurringPatternId { get; init; }
    public int ExpirationDays { get; init; } = 365; // Default to 1 year
} 