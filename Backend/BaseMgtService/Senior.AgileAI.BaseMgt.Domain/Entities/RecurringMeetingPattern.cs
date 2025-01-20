using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class RecurringMeetingPattern : BaseEntity
{
    public Guid Meeting_IdMeeting { get; set; }
    public required RecurrenceType RecurrenceType { get; set; }
    public required int Interval { get; set; }
    public required DateTime RecurringEndDate { get; set; }
    public DaysOfWeek? DaysOfWeek { get; set; }
    public bool IsCancelled { get; set; }
    public DateTime LastGeneratedDate { get; set; }
    public const int MaxFutureInstances = 5;  // Always maintain 5 future instances
    
    // Navigation Property
    public Meeting Meeting { get; set; } = null!;
    public ICollection<RecurringMeetingException> Exceptions { get; set; } = new List<RecurringMeetingException>();
} 