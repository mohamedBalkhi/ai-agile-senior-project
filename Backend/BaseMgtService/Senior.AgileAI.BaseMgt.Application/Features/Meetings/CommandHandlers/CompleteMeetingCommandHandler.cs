using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Exceptions;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class CompleteMeetingCommandHandler : IRequestHandler<CompleteMeetingCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;

    public CompleteMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<bool> Handle(CompleteMeetingCommand request, CancellationToken cancellationToken)
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
            throw new UnauthorizedAccessException("You don't have permission to complete this meeting");
        }

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Complete meeting
            meeting.Complete();

            // For online meetings, get recording from meeting service
            if (meeting.Type == MeetingType.Online)
            {
                // TODO: Integrate with meeting service
                // meeting.AudioUrl = await _meetingService.GetRecordingUrl(meeting.MeetingUrl);
                // meeting.AudioStatus = AudioStatus.Available;
                // meeting.AudioSource = AudioSource.MeetingService;
                // meeting.AudioUploadedAt = DateTime.UtcNow;
            }

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
                        Subject = $"Meeting Completed: {meeting.Title}",
                        Body = $"The meeting {meeting.Title} has been completed."
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