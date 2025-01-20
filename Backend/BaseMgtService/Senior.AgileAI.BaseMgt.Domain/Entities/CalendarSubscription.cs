using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class CalendarSubscription : BaseEntity
{
    public required Guid User_IdUser { get; set; }
    public required string Token { get; set; }
    public required CalendarFeedType FeedType { get; set; }
    public Guid? Project_IdProject { get; set; }
    public Guid? RecurringPattern_IdRecurringPattern { get; set; }
    public required DateTime ExpiresAt { get; set; }
    public required bool IsActive { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Project? Project { get; set; }
    public RecurringMeetingPattern? RecurringPattern { get; set; }
} 