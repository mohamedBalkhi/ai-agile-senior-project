using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.DTOs;

public class HomeDTO
{
    public required List<GetOrgProjectDTO> ActiveProjects { get; set; }
    public required List<MeetingDTO> UpcomingMeetings { get; set; }
    public int TotalProjectCount { get; set; }
    public int TotalUpcomingMeetingsCount { get; set; }
}