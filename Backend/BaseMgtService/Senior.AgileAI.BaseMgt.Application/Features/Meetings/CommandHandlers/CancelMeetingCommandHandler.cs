using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class CancelMeetingCommandHandler : IRequestHandler<CancelMeetingCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;

    public CancelMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<bool> Handle(CancelMeetingCommand request, CancellationToken cancellationToken)
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
            PrivilegeLevel.Write,
            cancellationToken);

        if (!hasAccess && meeting.Creator_IdOrganizationMember != request.UserId)
        {
            throw new UnauthorizedAccessException("You don't have permission to cancel this meeting");
        }

        // Verify meeting can be cancelled
        if (meeting.Status != MeetingStatus.Scheduled)
        {
            throw new InvalidOperationException("Only scheduled meetings can be cancelled");
        }

        // Keep track of members to notify
        var membersToNotify = meeting.MeetingMembers
            .Where(mm => mm.OrganizationMember.User != null)
            .Select(mm => mm.OrganizationMember)
            .ToList();

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Update meeting status
            meeting.Status = MeetingStatus.Cancelled;
            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Send notifications after successful transaction
            await SendCancellationNotificationsAsync(meeting, membersToNotify, cancellationToken);

            return true;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private async Task SendCancellationNotificationsAsync(
        Meeting meeting,
        List<OrganizationMember> membersToNotify,
        CancellationToken cancellationToken)
    {
        try
        {
            foreach (var member in membersToNotify)
            {
                if (member.User != null)
                {
                    // Email notification
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = member.User.Email,
                        Subject = $"Meeting Cancelled: {meeting.Title}",
                        Body = $"The following meeting has been cancelled:\n\n" +
                              $"Title: {meeting.Title}\n" +
                              $"Date: {meeting.StartTime}\n" +
                              $"Goal: {meeting.Goal}"
                    });

                    // Push notification
                    var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(member.User.Id, cancellationToken);
                    foreach (var token in userTokens)
                    {
                        await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                        {
                            Type = NotificationType.Firebase,
                            Recipient = token.Token,
                            Subject = "Meeting Cancelled",
                            Body = $"The meeting '{meeting.Title}' has been cancelled"
                        });
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // Log notification failures but don't throw
            // Consider implementing a retry mechanism or queueing failed notifications
            Console.WriteLine(ex.Message);
        }
    }
} 