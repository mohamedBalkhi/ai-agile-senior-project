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

    public async Task<GroupedMeetingsResponse> Handle(GetProjectMeetingsQuery request, CancellationToken cancellationToken)
    {
        // Check if project exists
        var project = await _unitOfWork.Projects.GetByIdAsync(request.ProjectId, cancellationToken);
        if (project == null)
        {
            throw new NotFoundException("Project not found");
        }

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            request.ProjectId,
            ProjectAspect.Meetings,
            PrivilegeLevel.Read,
            cancellationToken);

        if (!hasAccess)
        {
            throw new UnauthorizedAccessException("You don't have permission to view meetings in this project");
        }

        var now = DateTime.UtcNow;
        DateTime startDate, endDate;
        
        if (request.UpcomingOnly)
        {
            startDate = now;
            endDate = request.ToDate ?? now.AddDays(30);
        }
        else
        {
            startDate = request.FromDate ?? now.AddDays(-15);
            endDate = request.ToDate ?? (request.FromDate?.AddDays(30) ?? now.AddDays(15));
        }

        var (meetings, hasMorePast, hasMoreFuture) = await _unitOfWork.Meetings
            .GetProjectMeetingsInRangeAsync(
                request.ProjectId,
                startDate,
                endDate,
                request.PageSize,
                cancellationToken);

        // Group by date in meeting's timezone
        var groups = meetings
            .GroupBy(m => {
                var timeZone = TimeZoneInfo.FindSystemTimeZoneById(m.TimeZoneId);
                return TimeZoneInfo.ConvertTimeFromUtc(m.StartTime, timeZone).Date;
            })
            .OrderBy(g => g.Key)
            .Select(g => new MeetingGroupDTO
            {
                Date = g.Key,
                GroupTitle = GetGroupTitle(g.Key),
                Meetings = g.OrderBy(m => m.StartTime)
                           .Select(MapToDTO)
                           .ToList()
            })
            .ToList();

        // Never show past meetings option in upcoming view
        if (request.UpcomingOnly)
        {
            hasMorePast = false;
        }

        return new GroupedMeetingsResponse
        {
            Groups = groups,
            HasMorePast = hasMorePast,
            HasMoreFuture = hasMoreFuture,
            OldestMeetingDate = meetings.Any() ? meetings.Min(m => m.StartTime.Date) : null,
            NewestMeetingDate = meetings.Any() ? meetings.Max(m => m.StartTime.Date) : null
        };
    }

    private string GetGroupTitle(DateTime date)
    {
        var userDateTime = DateTime.UtcNow;  // You might want to pass user's timezone here
        var today = userDateTime.Date;
        var tomorrow = today.AddDays(1);
        var yesterday = today.AddDays(-1);

        return date.Date switch
        {
            var d when d == today => "Today",
            var d when d == tomorrow => "Tomorrow",
            var d when d == yesterday => "Yesterday",
            _ => date.ToString("dddd, MMMM d")
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
            HasAudio = !string.IsNullOrEmpty(meeting.AudioUrl)
        };
    }
}