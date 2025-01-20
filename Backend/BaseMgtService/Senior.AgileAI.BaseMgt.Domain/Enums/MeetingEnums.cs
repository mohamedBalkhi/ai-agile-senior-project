namespace Senior.AgileAI.BaseMgt.Domain.Enums;

public enum MeetingType
{
    InPerson,
    Online,
    Done
}

public enum MeetingStatus
{
    Scheduled,
    InProgress,
    Completed,
    Cancelled
}

public enum MeetingLanguage
{
    English,
    Arabic
}

public enum AudioStatus
{
    Pending,    // Waiting for upload/recording
    Available,  // Audio file is available
    Failed     // Upload/recording failed
}

public enum AudioSource
{
    Upload,          // For InPerson and Done meetings
    MeetingService   // For Online meetings
}

public enum RecurrenceType
{
    Daily,
    Weekly,
    Monthly
}

[Flags]
public enum DaysOfWeek
{
    None = 0,
    Sunday = 1,
    Monday = 2,
    Tuesday = 4,
    Wednesday = 8,
    Thursday = 16,
    Friday = 32,
    Saturday = 64
}

public enum AIProcessingStatus
{
    NotStarted,      // Initial state
    OnQueue,         // Submitted to AI service
    Processing,      // AI service is processing
    Completed,       // Processing completed successfully
    Failed          // Processing failed
}