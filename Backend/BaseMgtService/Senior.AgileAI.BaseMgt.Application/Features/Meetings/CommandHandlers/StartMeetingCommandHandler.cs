using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using FluentValidation;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class StartMeetingCommandHandler : IRequestHandler<StartMeetingCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;
    private readonly IOnlineMeetingService _onlineMeetingService;

    public StartMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService,
        IOnlineMeetingService onlineMeetingService)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
        _onlineMeetingService = onlineMeetingService;
    }

    public async Task<bool> Handle(StartMeetingCommand request, CancellationToken cancellationToken)
    {
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
            throw new UnauthorizedAccessException("You don't have permission to start this meeting");
        }

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // For online meetings, start recording
            if (meeting.Type == MeetingType.Online)
            {
                if (string.IsNullOrEmpty(meeting.LiveKitRoomName))
                {
                    throw new InvalidOperationException("Online meeting room not created");
                }

                // Start recording
                var audioUrl = await _onlineMeetingService.StartRecordingAsync(
                    meeting.LiveKitRoomName, 
                    cancellationToken);
                meeting.AudioUrl = audioUrl;
            }

            // Start meeting
            meeting.Start();
            
            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Notify members
            foreach (var member in meeting.MeetingMembers)
            {
                if (member.OrganizationMember?.User != null)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = member.OrganizationMember.User.Email,
                        Subject = $"Meeting Started: {meeting.Title}",
                        Body = $"The meeting {meeting.Title} has started.\n\n" +
                              $"Time: {meeting.StartTime}\n" +
                              $"Location: {meeting.Location ?? meeting.MeetingUrl}"
                    });
                }
            }

            return true;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }
} 