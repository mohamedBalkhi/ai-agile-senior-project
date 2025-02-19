using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;
using Senior.AgileAI.BaseMgt.Domain.Constants;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.QueryHandlers;

public class GetMeetingDetailsQueryHandler : IRequestHandler<GetMeetingDetailsQuery, MeetingDetailsDTO>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;

    public GetMeetingDetailsQueryHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
    }

    public async Task<MeetingDetailsDTO> Handle(GetMeetingDetailsQuery request, CancellationToken cancellationToken)
    {
        // Get meeting with details
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken);
        if (meeting == null)
        {
            throw new NotFoundException("Meeting not found");
        }

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            meeting.Project_IdProject,
            ProjectAspect.Meetings,
            PrivilegeLevel.Read,
            cancellationToken);

        if (!hasAccess)
        {
            throw new UnauthorizedAccessException("You don't have permission to view this meeting");
        }
        var recurringPattern = meeting.RecurringPattern ?? 
                              (meeting.OriginalMeeting?.RecurringPattern); 
        // Map to DTO
        var meetingDetails = new MeetingDetailsDTO
        {
            Id = meeting.Id,
            Title = meeting.Title,
            Goal = meeting.Goal,
            Language = meeting.Language,
            Type = meeting.Type,
            StartTime = meeting.StartTime,
            EndTime = meeting.EndTime,
            TimeZoneId = meeting.TimeZoneId,
            TimeZone = new TimeZoneDTO 
            {
                Id = meeting.TimeZone.Id,
                DisplayName = meeting.TimeZone.DisplayName,
                UtcOffset = meeting.TimeZone.UtcOffset.ToString(@"hh\:mm"),
                IsCommon = TimeZoneConstants.CommonTimeZones.Contains(meeting.TimeZone.Id)
            },
            Location = meeting.Location,
            MeetingUrl = meeting.MeetingUrl,
            AudioUrl = meeting.AudioUrl,
            ReminderTime = meeting.ReminderTime,
            Status = meeting.Status,
            // CreatorName = meeting.Creator.User.FUllName,
            // CreatorId = meeting.Creator.Id,
            Creator = new MeetingMemberDTO
            {
                MemberId = meeting.Creator.Id,
                MemberName = meeting.Creator.User.FUllName,
                UserId = meeting.Creator.User.Id,
                HasConfirmed = true,
                Email = meeting.Creator.User.Email,
                OrgMemberId = meeting.Creator.Id
            },
            Members = meeting.MeetingMembers?.Select(mm => new MeetingMemberDTO
            {
                MemberId = mm.OrganizationMember.Id,
                MemberName = mm.OrganizationMember.User.FUllName,
                HasConfirmed = mm.HasConfirmed,
                UserId = mm.OrganizationMember.User.Id,
                Email = mm.OrganizationMember.User.Email,
                OrgMemberId = mm.OrganizationMember.Id
            }).ToList() ?? new List<MeetingMemberDTO>(),
            IsRecurring = meeting.IsRecurring,
            IsRecurringInstance = meeting.IsRecurringInstance,
            OriginalMeetingId = meeting.OriginalMeeting_IdMeeting,
            // Include recurring pattern in initial object creation if it exists
            RecurringPattern = recurringPattern != null ? new RecurringMeetingPatternDTO
            {
                RecurrenceType = recurringPattern.RecurrenceType,
                Interval = recurringPattern.Interval,
                RecurringEndDate = recurringPattern.RecurringEndDate,
                DaysOfWeek = recurringPattern.DaysOfWeek
            } : null,
            ProjectId = meeting.Project_IdProject.ToString(),
            ProjectName = meeting.Project.Name
        };

        return meetingDetails;
    }
} 