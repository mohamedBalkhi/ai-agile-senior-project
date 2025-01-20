namespace Senior.AgileAI.BaseMgt.Domain.Entities;
public class RecurringMeetingException : BaseEntity
{
    public required Guid RecurringPattern_IdRecurringPattern { get; set; }
    public required DateTime ExceptionDate { get; set; }
    public required string Reason { get; set; }
    
    // Navigation property
    public RecurringMeetingPattern RecurringPattern { get; set; } = null!;
} 