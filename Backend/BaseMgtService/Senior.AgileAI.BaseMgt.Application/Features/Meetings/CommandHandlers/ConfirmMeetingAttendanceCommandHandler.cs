using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class ConfirmMeetingAttendanceCommandHandler : IRequestHandler<ConfirmMeetingAttendanceCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IRabbitMQService _rabbitMQService;

    public ConfirmMeetingAttendanceCommandHandler(
        IUnitOfWork unitOfWork,
        IRabbitMQService rabbitMQService)
    {
        _unitOfWork = unitOfWork;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<bool> Handle(ConfirmMeetingAttendanceCommand request, CancellationToken cancellationToken)
    {
        // Get meeting with details
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken);
        if (meeting == null)
        {
            throw new NotFoundException("Meeting not found");
        }

        // Get member
        var member = await _unitOfWork.OrganizationMembers.GetByUserId(
            request.UserId, 
            includeUser: true,
            cancellationToken);

        if (member == null)
        {
            throw new NotFoundException("Member not found");
        }

        // Check if member is part of the meeting
        var isMember = await _unitOfWork.MeetingMembers.IsMemberInMeetingAsync(
            request.MeetingId,
            member.Id,
            cancellationToken);

        if (!isMember)
        {
            throw new UnauthorizedAccessException("You are not a member of this meeting");
        }

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Update confirmation status
            var updated = await _unitOfWork.MeetingMembers.UpdateConfirmationAsync(
                request.MeetingId,
                member.Id,
                request.IsConfirmed,
                cancellationToken);

            if (!updated)
            {
                throw new InvalidOperationException("Failed to update confirmation status");
            }
            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Notify meeting creator
            if (meeting.Creator.User != null)
            {
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Email,
                    Recipient = meeting.Creator.User.Email,
                    Subject = $"Meeting Attendance Update: {meeting.Title}",
                    Body = $"{member.User?.FUllName} has {(request.IsConfirmed ? "confirmed" : "declined")} " +
                           $"attendance for the meeting:\n\n" +
                           $"Title: {meeting.Title}\n" +
                           $"Date: {meeting.StartTime}"
                });
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