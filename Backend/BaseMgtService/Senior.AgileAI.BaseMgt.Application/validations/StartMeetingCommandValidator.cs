using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class StartMeetingCommandValidator : AbstractValidator<StartMeetingCommand>
{
    private readonly IUnitOfWork _unitOfWork;

    public StartMeetingCommandValidator(IUnitOfWork unitOfWork)
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
                    return meeting?.Status == MeetingStatus.Scheduled;
                }).WithMessage("Only scheduled meetings can be started");

              

                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    if (meeting == null) return false;

                    var privilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                        meeting.Project_IdProject,
                        cmd.UserId,
                        ct);

                    return meeting.Creator_IdOrganizationMember == cmd.UserId ||
                           (privilege != null && privilege.Meetings >= PrivilegeLevel.Write);
                }).WithMessage("You don't have permission to start this meeting");

                RuleFor(x => x.MeetingId)
                    .MustAsync(async (cmd, id, ct) => {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                        Console.WriteLine($"Meeting: {meeting?.Id}");
                        if (meeting == null) return false;

                        var currentTimeUtc = DateTime.UtcNow;
                        var startTimeUtc = meeting.StartTime;
                        Console.WriteLine($"Current time: {currentTimeUtc}, Start time: {startTimeUtc}");
                        // Allow starting meeting within 30 minutes before scheduled time
                        return currentTimeUtc >= startTimeUtc.AddMinutes(-30) &&
                               currentTimeUtc <= startTimeUtc.AddMinutes(30);
                    })
                    .WithMessage("Meeting can only be started within 30 minutes of scheduled time");
            });

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required");
    }
} 