
namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public class GroupedMeetingsResponse
{
    public List<MeetingGroupDTO> Groups { get; set; } = new();
    public bool HasMorePast { get; set; }
    public bool HasMoreFuture { get; set; }
    public DateTime? OldestMeetingDate { get; set; }
    public DateTime? NewestMeetingDate { get; set; }
}

public class MeetingGroupDTO
{
    public string GroupTitle { get; set; } = string.Empty;  // "Today", "Tomorrow", "Sunday, November 24", etc.
    public DateTime Date { get; set; }
    public List<MeetingDTO> Meetings { get; set; } = new();
} 