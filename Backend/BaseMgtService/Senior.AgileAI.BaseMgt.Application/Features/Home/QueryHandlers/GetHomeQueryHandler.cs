using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.Home.Queries;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Features.Home.QueryHandlers;

public class GetHomeQueryHandler : IRequestHandler<GetHomeQuery, HomeDTO>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetHomeQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }
    public async Task<HomeDTO> Handle(GetHomeQuery request, CancellationToken cancellationToken)
    {
        var projects = await _unitOfWork.Projects.GetByUserIdAsync(request.UserId, cancellationToken);
        var meetings = await _unitOfWork.Meetings.GetUserMeetingsAsync(request.UserId, includeFullDetails: true,upcomingOnly: true, cancellationToken);
    
        return new HomeDTO
        {
            ActiveProjects = MapProjectsToDTO(projects),
            UpcomingMeetings = MapMeetingsToDTO(meetings),
            TotalProjectCount = projects.Count,
            TotalUpcomingMeetingsCount = meetings.Count
        };
    }

private List<GetOrgProjectDTO> MapProjectsToDTO(List<Project> projects)
{
    return projects.Select(p => new GetOrgProjectDTO {
        Id = p.Id,
        Name = p.Name,
        Description = p.Description,
        CreatedAt = p.CreatedDate,
        ProjectManager = p.ProjectManager.User.FUllName,
    }).ToList();
}
private List<MeetingDTO> MapMeetingsToDTO(List<Meeting> meetings)
{
    return meetings.Select(m => new MeetingDTO {
        Id = m.Id,
        Title = m.Title,
        StartTime = m.StartTime,
        EndTime = m.EndTime,
        ProjectId = m.Project_IdProject.ToString(),
        Type = m.Type,
        Status = m.Status,
        CreatorName = m.Creator?.User?.FUllName ?? "Unknown",
        CreatorId = m.Creator?.Id ?? Guid.Empty,
        TimeZoneId = m.TimeZoneId,
        MemberCount = m.MeetingMembers?.Count ?? 0,
        IsRecurring = m.IsRecurring,
        IsRecurringInstance = m.IsRecurringInstance,
        OriginalMeetingId = m.OriginalMeeting_IdMeeting,
        RecurringPattern = m.RecurringPattern != null ? new RecurringMeetingPatternDTO
        {
            RecurrenceType = m.RecurringPattern.RecurrenceType,
            Interval = m.RecurringPattern.Interval,
            RecurringEndDate = m.RecurringPattern.RecurringEndDate,
            DaysOfWeek = m.RecurringPattern.DaysOfWeek
        } : null,
        HasAudio = m.AudioStatus == AudioStatus.Available,
        ProjectName = m.Project?.Name ?? "Unknown"
    }).ToList();
}
}