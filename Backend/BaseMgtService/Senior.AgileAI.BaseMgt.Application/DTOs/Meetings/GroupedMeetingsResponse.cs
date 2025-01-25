namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public class GroupedMeetingsResponse
{
    public List<MeetingGroupDTO> Groups { get; set; } = new();
    
    // Pagination metadata
    public bool HasMore { get; set; }
    public string? LastMeetingId { get; set; }  // For cursor-based pagination
    public DateTime? ReferenceDate { get; set; } // Current reference date used
    public DateTime? NextReferenceDate { get; set; } // Reference date for next page
    public int TotalMeetingsCount { get; set; } // Total meetings in current response
}

public class MeetingGroupDTO
{
    public string GroupTitle { get; set; } = string.Empty;  // "Today", "Tomorrow", "Sunday, November 24", etc.
    public DateTime Date { get; set; }
    public List<MeetingDTO> Meetings { get; set; } = new();
} 