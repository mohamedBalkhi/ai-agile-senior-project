using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class ConfirmMeetingAttendanceCommandValidator : AbstractValidator<ConfirmMeetingAttendanceCommand>
{
    private readonly IUnitOfWork _unitOfWork;

    public ConfirmMeetingAttendanceCommandValidator(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;

        RuleFor(x => x.MeetingId)
            .NotEmpty().WithMessage("Meeting ID is required")
            .MustAsync(async (cmd, id, ct) => {
                var meeting = await _unitOfWork.Meetings.GetByIdAsync(id);
                return meeting != null;
            }).WithMessage("Meeting not found")
            .MustAsync(async (cmd, id, ct) => {
                var meeting = await _unitOfWork.Meetings.GetByIdAsync(id);
                return meeting?.Status == MeetingStatus.Scheduled;
            }).WithMessage("Can only confirm attendance for scheduled meetings");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required")
            .MustAsync(async (cmd, userId, ct) => {
                var member = await _unitOfWork.OrganizationMembers.GetByUserId(userId);
                return member != null;
            }).WithMessage("Invalid user ID");
    }
} 