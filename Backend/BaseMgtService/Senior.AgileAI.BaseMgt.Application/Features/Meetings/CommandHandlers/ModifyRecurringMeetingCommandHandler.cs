using MediatR;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class ModifyRecurringMeetingCommandHandler : IRequestHandler<ModifyRecurringMeetingCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IRecurringMeetingService _recurringMeetingService;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;

    public ModifyRecurringMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IRecurringMeetingService recurringMeetingService,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService)
    {
        _unitOfWork = unitOfWork;
        _recurringMeetingService = recurringMeetingService;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<bool> Handle(ModifyRecurringMeetingCommand request, CancellationToken cancellationToken)
    {
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken);
        if (meeting == null)
            throw new NotFoundException("Meeting not found");

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            meeting.Project_IdProject,
            ProjectAspect.Meetings,
            PrivilegeLevel.Write,
            cancellationToken);

        if (!hasAccess && meeting.Creator_IdOrganizationMember != request.UserId)
        {
            throw new UnauthorizedAccessException("You don't have permission to modify this meeting");
        }

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Update the current meeting
            await UpdateMeetingDetails(meeting, request.Dto, cancellationToken);

            if (request.Dto.ApplyToSeries && (meeting.RecurringPattern != null || meeting.OriginalMeeting?.RecurringPattern != null))
            {
                var futureInstances = await _unitOfWork.Meetings.GetFutureRecurringInstances(
                    meeting.RecurringPattern?.Id ?? meeting.OriginalMeeting!.RecurringPattern!.Id,
                    DateTime.UtcNow,
                    cancellationToken);

                foreach (var instance in futureInstances.Where(i => i.Id != meeting.Id))
                {
                    await UpdateMeetingDetails(instance, request.Dto, cancellationToken);

                    // Handle time updates while preserving the series pattern
                    if (request.Dto.StartTime.HasValue)
                    {
                        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
                            request.Dto.TimeZone ?? instance.TimeZoneId);
                        
                        var newBaseTime = TimeZoneInfo.ConvertTimeToUtc(
                            DateTime.SpecifyKind(request.Dto.StartTime.Value, DateTimeKind.Unspecified),
                            timeZoneInfo);

                        var originalOffset = instance.StartTime - instance.StartTime.Date;
                        var newStartTime = instance.StartTime.Date.Add(newBaseTime.TimeOfDay);
                        var duration = request.Dto.EndTime.HasValue 
                            ? request.Dto.EndTime.Value - request.Dto.StartTime.Value
                            : instance.EndTime - instance.StartTime;

                        instance.StartTime = newStartTime;
                        instance.EndTime = newStartTime.Add(duration);

                        if (request.Dto.ReminderTime.HasValue)
                        {
                            var reminderOffset = request.Dto.StartTime.Value - request.Dto.ReminderTime.Value;
                            instance.ReminderTime = newStartTime - reminderOffset;
                        }
                    }
                }
                if (request.Dto.Status.HasValue && request.Dto.Status.Value == MeetingStatus.Cancelled)
                {
                    if (meeting.RecurringPattern != null)
                    {
                        meeting.RecurringPattern!.IsCancelled = true;
                    }
                    else if (meeting.OriginalMeeting?.RecurringPattern != null)
                    {
                        meeting.OriginalMeeting!.RecurringPattern!.IsCancelled = true;
                    }
                }
            }
            else if (meeting.IsRecurringInstance && meeting.OriginalMeeting?.RecurringPattern != null)
            {
                // Create exception for this instance
                await _recurringMeetingService.AddException(
                    meeting.OriginalMeeting!.RecurringPattern!.Id,
                    meeting.StartTime,
                    "Modified instance");
            }

            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Send notifications
            await SendNotificationsAsync(meeting, request.Dto, cancellationToken);

            return true;
        }
        catch (Exception e)
        {
            await transaction.RollbackAsync(cancellationToken);
            Console.WriteLine($"Error modifying recurring meeting {request.MeetingId} {e.Message} {e.StackTrace}");
            throw;
        }
    }

    private async Task UpdateMeetingDetails(Meeting meeting, ModifyRecurringMeetingDto dto, CancellationToken cancellationToken)
    {
        if (dto.Title != null)
            meeting.Title = dto.Title;
        
        if (dto.Goal != null)
            meeting.Goal = dto.Goal;
        
        if (dto.Language.HasValue)
            meeting.Language = dto.Language.Value;
        
        if (dto.TimeZone != null)
            meeting.TimeZoneId = dto.TimeZone;
        
        if (dto.Location != null)
            meeting.Location = dto.Location;

        if (dto.Status.HasValue)
        {
            // Validate status transition
            if (!IsValidStatusTransition(meeting.Status, dto.Status.Value))
                throw new InvalidOperationException($"Invalid status transition from {meeting.Status} to {dto.Status.Value}");
            
            meeting.Status = dto.Status.Value;
        }

        // Handle member changes
        if (dto.AddMembers?.Any() == true)
        {
            foreach (var memberId in dto.AddMembers)
            {
                if (!meeting.MeetingMembers.Any(mm => mm.OrganizationMember_IdOrganizationMember == memberId))
                {
                    var newMember = new MeetingMember
                    {
                        Meeting_IdMeeting = meeting.Id,
                        OrganizationMember_IdOrganizationMember = memberId,
                        HasConfirmed = false
                    };
                    await _unitOfWork.MeetingMembers.AddAsync(newMember, cancellationToken);
                }
            }
        }

        if (dto.RemoveMembers?.Any() == true)
        {
            var membersToRemove = meeting.MeetingMembers
                .Where(mm => dto.RemoveMembers.Contains(mm.OrganizationMember_IdOrganizationMember))
                .ToList();

            foreach (var member in membersToRemove)
            {
                _unitOfWork.MeetingMembers.Remove(member);
            }
        }
    }

    private bool IsValidStatusTransition(MeetingStatus currentStatus, MeetingStatus newStatus)
    {
        return (currentStatus, newStatus) switch
        {
            (MeetingStatus.Scheduled, MeetingStatus.Cancelled) => true,
            (MeetingStatus.Scheduled, MeetingStatus.InProgress) => true,
            (MeetingStatus.InProgress, MeetingStatus.Completed) => true,
            (MeetingStatus.InProgress, MeetingStatus.Cancelled) => true,
            _ => false
        };
    }

    private async Task SendNotificationsAsync(Meeting meeting, ModifyRecurringMeetingDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var notifications = new List<NotificationMessage>();

            // Notify about status changes
            if (dto.Status.HasValue)
            {
                foreach (var member in meeting.MeetingMembers)
                {
                    if (member.OrganizationMember?.User != null)
                    {
                        notifications.Add(new NotificationMessage
                        {
                            Type = NotificationType.Email,
                            Recipient = member.OrganizationMember.User.Email,
                            Subject = $"Meeting Status Updated: {meeting.Title}",
                            Body = $"The meeting '{meeting.Title}' status has been changed to {dto.Status.Value}"
                        });
                    }
                }
            }

            // Notify new members
            if (dto.AddMembers?.Any() == true)
            {
                foreach (var memberId in dto.AddMembers)
                {
                    var member = await _unitOfWork.OrganizationMembers.GetByIdAsync(memberId,includeUser:true, cancellationToken);
                    if (member?.User != null)
                    {
                        notifications.Add(new NotificationMessage
                        {
                            Type = NotificationType.Email,
                            Recipient = member.User.Email,
                            Subject = $"New Meeting Invitation: {meeting.Title}",
                            Body = GetInvitationBody(meeting, member, dto.ApplyToSeries)
                        });
                    }
                }
            }

            // Notify removed members
            if (dto.RemoveMembers?.Any() == true)
            {
                foreach (var memberId in dto.RemoveMembers)
                {
                    var member = await _unitOfWork.OrganizationMembers.GetByIdAsync(memberId,includeUser:true, cancellationToken);
                    if (member?.User != null)
                    {
                        notifications.Add(new NotificationMessage
                        {
                            Type = NotificationType.Email,
                            Recipient = member.User.Email,
                            Subject = $"Removed from Meeting: {meeting.Title}",
                            Body = $"You have been removed from the meeting '{meeting.Title}'"
                        });
                    }
                }
            }

            // Notify about general updates
            if (dto.Title != null || dto.StartTime.HasValue || dto.Location != null)
            {
                foreach (var member in meeting.MeetingMembers)
                {
                    if (member.OrganizationMember?.User != null)
                    {
                        notifications.Add(new NotificationMessage
                        {
                            Type = NotificationType.Email,
                            Recipient = member.OrganizationMember.User.Email,
                            Subject = $"Meeting Updated: {meeting.Title}",
                            Body = GetUpdateBody(meeting, member.OrganizationMember, dto)
                        });
                    }
                }
            }

            // Send all notifications
            foreach (var notification in notifications)
            {
                await _rabbitMQService.PublishNotificationAsync(notification);
            }
        }
        catch (Exception ex)
        {
            // Log but don't throw - notifications shouldn't break the main operation
            Console.WriteLine($"Error sending notifications: {ex.Message}");
        }
    }

    private string GetInvitationBody(Meeting meeting, OrganizationMember member, bool isSeriesInvitation)
    {
        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(meeting.TimeZoneId);
        var localStartTime = TimeZoneInfo.ConvertTimeFromUtc(meeting.StartTime, timeZoneInfo);
        
        return $"You have been invited to {(isSeriesInvitation ? "a recurring meeting series" : "a meeting")}:\n\n" +
               $"Title: {meeting.Title}\n" +
               $"Date: {localStartTime:f} ({meeting.TimeZoneId})\n" +
               $"Location: {meeting.Location ?? "Online"}\n" +
               $"Goal: {meeting.Goal}";
    }

    private string GetUpdateBody(Meeting meeting, OrganizationMember recipient, ModifyRecurringMeetingDto dto)
    {
        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(meeting.TimeZoneId);
        var localStartTime = TimeZoneInfo.ConvertTimeFromUtc(meeting.StartTime, timeZoneInfo);

        var changes = new List<string>();
        if (dto.Title != null) changes.Add($"Title updated to: {dto.Title}");
        if (dto.StartTime.HasValue) changes.Add($"Time updated to: {localStartTime:f} ({meeting.TimeZoneId})");
        if (dto.Location != null) changes.Add($"Location updated to: {dto.Location}");
        if (dto.Goal != null) changes.Add($"Goal updated to: {dto.Goal}");

        return $"The following changes have been made to {(dto.ApplyToSeries ? "the meeting series" : "the meeting")}:\n\n" +
               string.Join("\n", changes);
    }
} 