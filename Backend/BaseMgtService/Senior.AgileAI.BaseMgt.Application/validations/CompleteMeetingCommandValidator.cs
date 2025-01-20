using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class CompleteMeetingCommandValidator : AbstractValidator<CompleteMeetingCommand>
{
    private readonly IUnitOfWork _unitOfWork;

    public CompleteMeetingCommandValidator(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;

        ClassLevelCascadeMode = CascadeMode.Stop;
        RuleLevelCascadeMode = CascadeMode.Stop;

        RuleFor(x => x.MeetingId)
            .NotEmpty().WithMessage("Meeting ID is required")
            .MustAsync(async (cmd, id, ct) => {
                var meeting = await _unitOfWork.Meetings.GetByIdAsync(id);
                return meeting != null;
            }).WithMessage("Meeting not found")
            .DependentRules(() => {
                RuleFor(x => x.MeetingId).MustAsync(async (cmd, id, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(id);
                    return meeting?.Status == MeetingStatus.InProgress;
                }).WithMessage("Only in-progress meetings can be completed");

                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    if (meeting == null) return false;

                    var privilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                        meeting.Project_IdProject,
                        cmd.UserId,
                        ct);

                    return meeting.Creator_IdOrganizationMember == cmd.UserId ||
                           (privilege != null && privilege.Meetings >= PrivilegeLevel.Write);
                }).WithMessage("You don't have permission to complete this meeting");

                // For in-person meetings, check if audio is required
                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    return meeting?.Type != MeetingType.InPerson || 
                           meeting.AudioStatus == AudioStatus.Available;
                }).WithMessage("In-person meetings require audio upload before completion");
            });

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required");
    }
} 