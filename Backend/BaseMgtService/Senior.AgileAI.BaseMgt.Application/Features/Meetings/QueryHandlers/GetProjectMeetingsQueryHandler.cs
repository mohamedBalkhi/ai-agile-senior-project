using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using System;
using System.Globalization;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.QueryHandlers;

public class GetProjectMeetingsQueryHandler : IRequestHandler<GetProjectMeetingsQuery, GroupedMeetingsResponse>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;

    public GetProjectMeetingsQueryHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
    }

    public async Task<GroupedMeetingsResponse> Handle(
        GetProjectMeetingsQuery request,
        CancellationToken cancellationToken)
    {
        // Authorization and timezone conversion
        var project = await _unitOfWork.Projects.GetByIdAsync(request.ProjectId, cancellationToken);
        if (project == null) throw new NotFoundException("Project not found");

        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId, request.ProjectId, ProjectAspect.Meetings, PrivilegeLevel.Read, cancellationToken);
        if (!hasAccess) throw new UnauthorizedAccessException();

        var userTimeZone = TimeZoneInfo.FindSystemTimeZoneById(request.TimeZoneId);

        // Fetch meetings
        var (meetings, hasMore) = await _unitOfWork.Meetings.GetProjectMeetingsInRangeAsync(
            request.ProjectId,
            request.ReferenceDate,
            request.PageSize,
            request.IsUpcoming,
            request.LastMeetingId,
            cancellationToken);

        // Group meetings
        var groups = meetings
            .GroupBy(m => TimeZoneInfo.ConvertTimeFromUtc(m.StartTime, userTimeZone).Date)
            .Select(g => new MeetingGroupDTO
            {
                Date = g.Key,
                GroupTitle = GetGroupTitle(g.Key, userTimeZone),
                Meetings = request.IsUpcoming
                    ? g.OrderBy(m => m.StartTime).Select(MapToDTO).ToList()
                    : g.OrderByDescending(m => m.StartTime).Select(MapToDTO).ToList()
            })
            .ToList();

        // Get next reference date and last meeting ID for pagination
        var lastMeeting = meetings.LastOrDefault();
        var nextReferenceDate = lastMeeting?.EndTime;

        // Return enhanced response
        return new GroupedMeetingsResponse
        {
            Groups = groups,
            HasMore = hasMore,
            LastMeetingId = lastMeeting?.Id.ToString(),
            ReferenceDate = request.ReferenceDate,
            NextReferenceDate = nextReferenceDate,
            TotalMeetingsCount = meetings.Count
        };
    }

    private string GetGroupTitle(DateTime date, TimeZoneInfo userTimeZone)
    {
        // Convert UTC "now" to user's local time
        var userNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, userTimeZone);
        var userDate = TimeZoneInfo.ConvertTimeFromUtc(date, userTimeZone).Date;

        var today = userNow.Date;
        var tomorrow = today.AddDays(1);
        var yesterday = today.AddDays(-1);

        return userDate switch
        {
            var d when d == today => "Today",
            var d when d == tomorrow => "Tomorrow",
            var d when d == yesterday => "Yesterday",
            _ => userDate.ToString("dddd, MMMM d")
        };
    }

    private MeetingDTO MapToDTO(Meeting meeting)
    {
        var recurringPattern = meeting.RecurringPattern ?? meeting.OriginalMeeting?.RecurringPattern;
        return new MeetingDTO
        {
            Id = meeting.Id,
            Title = meeting.Title,
            StartTime = meeting.StartTime,
            EndTime = meeting.EndTime,
            Type = meeting.Type,
            Status = meeting.Status,
            CreatorName = meeting.Creator?.User?.FUllName ?? string.Empty,
            TimeZoneId = meeting.TimeZoneId,
            ProjectId = meeting.Project_IdProject.ToString(),
            ProjectName = meeting.Project?.Name ?? string.Empty,
            MemberCount = meeting.MeetingMembers.Count,
            IsRecurring = meeting.IsRecurring,
            IsRecurringInstance = meeting.IsRecurringInstance,
            OriginalMeetingId = meeting.OriginalMeeting_IdMeeting,
            RecurringPattern = recurringPattern != null ? new RecurringMeetingPatternDTO
            {
                RecurrenceType = recurringPattern.RecurrenceType,
                Interval = recurringPattern.Interval,
                RecurringEndDate = recurringPattern.RecurringEndDate,
                DaysOfWeek = recurringPattern.DaysOfWeek
            } : null,
            HasAudio = !string.IsNullOrEmpty(meeting.AudioUrl),
            CreatedDate = meeting.CreatedDate
        };
    }
}