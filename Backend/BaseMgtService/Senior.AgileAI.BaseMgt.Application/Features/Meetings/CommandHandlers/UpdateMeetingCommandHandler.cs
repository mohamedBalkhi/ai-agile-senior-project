using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Exceptions;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class UpdateMeetingCommandHandler : IRequestHandler<UpdateMeetingCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;

    public UpdateMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<bool> Handle(UpdateMeetingCommand request, CancellationToken cancellationToken)
    {
        // Get meeting with details
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.Dto.MeetingId, cancellationToken);
        if (meeting == null)
        {
            throw new NotFoundException("Meeting not found");
        }

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            meeting.Project_IdProject,
            ProjectAspect.Meetings,
            PrivilegeLevel.Write,
            cancellationToken);

        if (!hasAccess && meeting.Creator_IdOrganizationMember != request.UserId)
        {
            throw new UnauthorizedAccessException("You don't have permission to update this meeting");
        }

        // Keep track of added/removed members for notifications
        var addedMembers = new List<OrganizationMember>();
        var removedMembers = new List<OrganizationMember>();

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Convert times to UTC before updating
            var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
                request.Dto.TimeZone ?? meeting.TimeZoneId);

            if (request.Dto.StartTime.HasValue)
            {
                var startTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                    DateTime.SpecifyKind(request.Dto.StartTime.Value, DateTimeKind.Unspecified), 
                    timeZoneInfo);
                meeting.StartTime = startTimeUtc;
            }

            if (request.Dto.EndTime.HasValue)
            {
                var endTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                    DateTime.SpecifyKind(request.Dto.EndTime.Value, DateTimeKind.Unspecified), 
                    timeZoneInfo);
                meeting.EndTime = endTimeUtc;
            }

            if (request.Dto.ReminderTime.HasValue)
            {
                var reminderTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                    DateTime.SpecifyKind(request.Dto.ReminderTime.Value, DateTimeKind.Unspecified), 
                    timeZoneInfo);
                meeting.ReminderTime = reminderTimeUtc;
            }

            // Update other properties
            if (request.Dto.Title != null)
                meeting.Title = request.Dto.Title;
            if (request.Dto.Goal != null)
                meeting.Goal = request.Dto.Goal;
            if (request.Dto.Language.HasValue)
                meeting.Language = request.Dto.Language.Value;
            if (request.Dto.TimeZone != null)
                meeting.TimeZoneId = request.Dto.TimeZone;
            if (request.Dto.Location != null)
                meeting.Location = request.Dto.Location;

            // Handle member changes
            if (request.Dto.AddMembers?.Any() == true)
            {
                foreach (var memberId in request.Dto.AddMembers)
                {
                    if (!meeting.MeetingMembers.Any(mm => 
                        mm.OrganizationMember.Id == memberId))
                    {
                        var orgMember = await _unitOfWork.OrganizationMembers.GetByIdAsync(
                            memberId,
                            includeUser: true,
                            cancellationToken);

                        if (orgMember != null)
                        {
                            var newMember = new MeetingMember
                            {
                                Meeting_IdMeeting = meeting.Id,
                                OrganizationMember_IdOrganizationMember = orgMember.Id,
                                HasConfirmed = false
                            };
                            await _unitOfWork.MeetingMembers.AddAsync(newMember, cancellationToken);
                            addedMembers.Add(orgMember);
                        }
                    }
                }
            }

            if (request.Dto.RemoveMembers?.Any() == true)
            {
                var membersToRemove = meeting.MeetingMembers
                    .Where(mm => request.Dto.RemoveMembers.Contains(mm.OrganizationMember.Id))
                    .ToList();

                foreach (var member in membersToRemove)
                {
                    _unitOfWork.MeetingMembers.Remove(member);
                    removedMembers.Add(member.OrganizationMember);
                }
            }

            // Update recurring pattern if provided
            if (request.Dto.RecurringPattern != null && meeting.RecurringPattern != null)
            {
                meeting.RecurringPattern.RecurrenceType = request.Dto.RecurringPattern.RecurrenceType;
                meeting.RecurringPattern.Interval = request.Dto.RecurringPattern.Interval;
                meeting.RecurringPattern.RecurringEndDate = request.Dto.RecurringPattern.RecurringEndDate;
                meeting.RecurringPattern.DaysOfWeek = request.Dto.RecurringPattern.DaysOfWeek;
            }

            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Send notifications after successful transaction
            await SendNotificationsAsync(meeting, addedMembers, removedMembers, cancellationToken);

            return true;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private async Task SendNotificationsAsync(
        Meeting meeting,
        List<OrganizationMember> addedMembers,
        List<OrganizationMember> removedMembers,
        CancellationToken cancellationToken)
    {
        try
        {
            // Notify new members
            foreach (var member in addedMembers)
            {
                if (member.User != null)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = member.User.Email,
                        Subject = $"New Meeting Invitation: {meeting.Title}",
                        Body = $"You have been invited to a meeting:\n\nTitle: {meeting.Title}\nDate: {meeting.StartTime}\nGoal: {meeting.Goal}"
                    });

                    var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(member.User.Id, cancellationToken);
                    foreach (var token in userTokens)
                    {
                        await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                        {
                            Type = NotificationType.Firebase,
                            Recipient = token.Token,
                            Subject = "New Meeting Invitation",
                            Body = $"You've been invited to: {meeting.Title}"
                        });
                    }
                }
            }

            // Notify removed members
            foreach (var member in removedMembers)
            {
                if (member.User != null)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = member.User.Email,
                        Subject = $"Removed from Meeting: {meeting.Title}",
                        Body = $"You have been removed from the meeting: {meeting.Title}"
                    });
                }
            }

            // Notify all remaining members about updates
            foreach (var member in meeting.MeetingMembers)
            {
                if (member.OrganizationMember?.User != null)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = member.OrganizationMember.User.Email,
                        Subject = $"Meeting Updated: {meeting.Title}",
                        Body = GetNotificationBody(meeting, member.OrganizationMember)
                    });
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
        }
    }

    private string GetNotificationBody(Meeting meeting, OrganizationMember recipient)
    {
        var recipientTimeZone = TimeZoneInfo.FindSystemTimeZoneById(meeting.TimeZoneId);
        var meetingTimeInRecipientZone = TimeZoneInfo.ConvertTimeFromUtc(
            meeting.StartTime, 
            recipientTimeZone);

        return $"Meeting details have been updated:\n\n" +
               $"Title: {meeting.Title}\n" +
               $"Date: {meetingTimeInRecipientZone:f} ({meeting.TimeZoneId})\n" +
               $"Location: {meeting.Location ?? meeting.MeetingUrl}\n" +
               $"Goal: {meeting.Goal}";
    }
} 