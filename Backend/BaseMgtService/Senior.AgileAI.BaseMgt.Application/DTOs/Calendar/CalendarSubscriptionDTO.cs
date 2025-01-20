namespace Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;

public record CalendarSubscriptionDTO
{
    public required string FeedUrl { get; init; }
    public required DateTime ExpiresAt { get; init; }
    public required string FeedType { get; init; }
    public string? ProjectName { get; init; }
    public string? SeriesTitle { get; init; }
} 