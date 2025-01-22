using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Domain.ValueObjects;

namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Meeting : BaseEntity
{
    public required string Title { get; set; }
    public required string Goal { get; set; }
    public required MeetingLanguage Language { get; set; }
    public required MeetingType Type { get; set; }
    public required DateTime StartTime { get; set; }
    public required DateTime EndTime { get; set; }
    public DateTime? ActualEndTime { get; set; }
    public required string TimeZoneId { get; set; }
    private TimeZoneValue? _timeZone;
    public TimeZoneValue TimeZone => _timeZone ??= TimeZoneValue.FromId(TimeZoneId);
    
    public string? Location { get; set; }
    public string? MeetingUrl { get; set; }
    
    // Online Meeting Properties
    public string? LiveKitRoomSid { get; set; }  // The room SID from LiveKit
    public string? LiveKitRoomName { get; set; }  // The room name we generate
    public OnlineMeetingStatus OnlineMeetingStatus { get; set; }
    public DateTime? OnlineMeetingStartedAt { get; set; }
    public DateTime? OnlineMeetingEndedAt { get; set; }
    
    public string? AudioUrl { get; set; }
    public AudioStatus AudioStatus { get; set; }
    public AudioSource AudioSource { get; set; }
    public DateTime? AudioUploadedAt { get; set; }
    
    // AI Processing Properties
    public string? AIProcessingToken { get; set; }
    public AIProcessingStatus AIProcessingStatus { get; set; } = AIProcessingStatus.NotStarted;
    public MeetingAIReport? AIReport { get; set; }
    public DateTime? AIProcessedAt { get; set; }
    
    public DateTime? ReminderTime { get; set; }
    public bool ReminderSent { get; set; }
    public MeetingStatus Status { get; set; } = MeetingStatus.Scheduled;
    
    // Foreign Keys
    public Guid Project_IdProject { get; set; }
    public Guid Creator_IdOrganizationMember { get; set; }
    
    // Navigation Properties
    public Project Project { get; set; } = null!;
    public OrganizationMember Creator { get; set; } = null!;
    public ICollection<MeetingMember> MeetingMembers { get; set; } = new List<MeetingMember>();
    
    // Helper Properties
    public bool IsScheduled => Status == MeetingStatus.Scheduled;
    public bool RequiresAudioUpload => Type != MeetingType.Online && AudioUrl == null;
    
    // Add these new properties
    public Guid? OriginalMeeting_IdMeeting { get; set; }  // Reference to the original meeting if this is a recurring instance
    public bool IsRecurringInstance => OriginalMeeting_IdMeeting.HasValue;
    
    // Navigation Properties
    public Meeting? OriginalMeeting { get; set; }  // Navigation property to the original meeting
    public ICollection<Meeting> RecurringInstances { get; set; } = new List<Meeting>();  // Collection of instances
    public virtual RecurringMeetingPattern? RecurringPattern { get; set; }
    
    // Update IsRecurring property
    public bool IsRecurring => RecurringPattern != null || IsRecurringInstance;

    // Helper methods for time conversion
    public DateTime GetStartTimeInTimeZone()
    {
        return TimeZoneInfo.ConvertTime(StartTime, TimeZone.GetTimeZoneInfo());
    }

    public DateTime GetEndTimeInTimeZone()
    {
        return TimeZoneInfo.ConvertTime(EndTime, TimeZone.GetTimeZoneInfo());
    }

    // Add helper methods for status transitions
    public void Start()
    {
        if (Status != MeetingStatus.Scheduled)
            throw new InvalidOperationException("Only scheduled meetings can be started");
        
        Status = MeetingStatus.InProgress;
        
        if (Type == MeetingType.Online)
        {
            OnlineMeetingStatus = OnlineMeetingStatus.Active;
            OnlineMeetingStartedAt = DateTime.UtcNow;
            AudioStatus = AudioStatus.Pending;  // Recording starts automatically
            AudioSource = AudioSource.MeetingService;
        }
        
        StartTime = DateTime.UtcNow;
    }

    public void Complete()
    {
        if (Status != MeetingStatus.InProgress)
            throw new InvalidOperationException("Only in-progress meetings can be completed");
            
        Status = MeetingStatus.Completed;
        ActualEndTime = DateTime.UtcNow;
        
        if (Type == MeetingType.Online)
        {
            OnlineMeetingStatus = OnlineMeetingStatus.Ended;
            OnlineMeetingEndedAt = DateTime.UtcNow;
            if (AudioUrl != null)
            {
                AudioStatus = AudioStatus.Available;
            }
        }
    }

    // Add validation methods
    public bool CanUploadAudio() => 
        Type != MeetingType.Online && 
        (Status == MeetingStatus.InProgress || Status == MeetingStatus.Completed);

    public bool RequiresMembers() => Type == MeetingType.Online;

    // AI Processing helper methods
    public bool CanProcessAudio() =>
        AudioStatus == AudioStatus.Available && 
        AIProcessingStatus == AIProcessingStatus.NotStarted;

    public void InitiateAIProcessing(string processingToken)
    {
        if (!CanProcessAudio())
            throw new InvalidOperationException("Cannot initiate AI processing - audio not available or processing already started");

        AIProcessingToken = processingToken;
        AIProcessingStatus = AIProcessingStatus.OnQueue;
    }

    public void UpdateAIProcessingStatus(AIProcessingStatus newStatus)
    {
        if (AIProcessingStatus == AIProcessingStatus.Completed)
            throw new InvalidOperationException("Cannot update status of completed processing");

        AIProcessingStatus = newStatus;
        
        if (newStatus == AIProcessingStatus.Completed)
            AIProcessedAt = DateTime.UtcNow;
    }

    public void SetAIReport(MeetingAIReport report)
    {
        if (AIProcessingStatus != AIProcessingStatus.Completed)
            throw new InvalidOperationException("Cannot set AI report before processing is completed");

        AIReport = report;
        AIProcessedAt = DateTime.UtcNow;
    }

    // Helper methods for online meetings
    public string GenerateRoomName() => $"meeting-{Id}";

    public bool IsOnlineMeetingActive() => 
        Type == MeetingType.Online && 
        OnlineMeetingStatus == OnlineMeetingStatus.Active;
}