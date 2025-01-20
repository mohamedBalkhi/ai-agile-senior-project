using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class UpdateMeetingCommandValidator : AbstractValidator<UpdateMeetingCommand>
{
    private readonly ITimeZoneService _timeZoneService;
    private readonly IUnitOfWork _unitOfWork;

    public UpdateMeetingCommandValidator(ITimeZoneService timeZoneService, IUnitOfWork unitOfWork)
    {
        _timeZoneService = timeZoneService;
        _unitOfWork = unitOfWork;

        ClassLevelCascadeMode = CascadeMode.Stop;
        RuleLevelCascadeMode = CascadeMode.Stop;

        RuleFor(x => x.Dto.MeetingId)
            .NotEmpty().WithMessage("Meeting ID is required")
            .MustAsync(async (meetingId, ct) => {
                var meeting = await _unitOfWork.Meetings.GetByIdAsync(meetingId, ct);
                return meeting != null;
            }).WithMessage("Invalid meeting ID")
            .DependentRules(() => {
                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                    if (meeting == null) return false;

                    var privilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                        meeting.Project_IdProject,
                        cmd.UserId,
                        ct);

                    return meeting.Creator_IdOrganizationMember == cmd.UserId ||
                           (privilege != null && privilege.Meetings >= PrivilegeLevel.Write);
                }).WithMessage("You don't have permission to update this meeting");
            });

        When(x => x.Dto.Title != null, () => {
            RuleFor(x => x.Dto.Title)
                .MaximumLength(200).WithMessage("Title cannot exceed 200 characters");
        });

        When(x => x.Dto.Goal != null, () => {
            RuleFor(x => x.Dto.Goal)
                .MaximumLength(1000).WithMessage("Goal cannot exceed 1000 characters");
        });

        When(x => x.Dto.StartTime.HasValue, () => {
            RuleFor(x => x)
                .MustAsync(async (cmd, ct) => {
                    try {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                        if (meeting == null) return false;

                        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
                            cmd.Dto.TimeZone ?? meeting.TimeZoneId);
                        
                        var startTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                            DateTime.SpecifyKind(cmd.Dto.StartTime!.Value, DateTimeKind.Unspecified),
                            timeZoneInfo);

                        return startTimeUtc > DateTime.UtcNow;
                    }
                    catch {
                        return false;
                    }
                })
                .WithMessage("Start time must be in the future")
                .DependentRules(() => {
                    RuleFor(x => x).MustAsync(async (cmd, ct) => {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                        return !meeting!.IsRecurring || meeting.Status == MeetingStatus.Scheduled;
                    }).WithMessage("Cannot update start time of a recurring meeting that has already started");
                });
        });

        When(x => x.Dto.EndTime.HasValue, () => {
            RuleFor(x => x)
                .MustAsync(async (cmd, ct) => {
                    try {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                        if (meeting == null) return false;

                        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
                            cmd.Dto.TimeZone ?? meeting.TimeZoneId);
                        
                        var startTimeUtc = cmd.Dto.StartTime.HasValue 
                            ? TimeZoneInfo.ConvertTimeToUtc(
                                DateTime.SpecifyKind(cmd.Dto.StartTime.Value, DateTimeKind.Unspecified),
                                timeZoneInfo)
                            : meeting.StartTime;
                        
                        var endTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                            DateTime.SpecifyKind(cmd.Dto.EndTime!.Value, DateTimeKind.Unspecified),
                            timeZoneInfo);

                        return endTimeUtc > startTimeUtc;
                    }
                    catch {
                        return false;
                    }
                })
                .WithMessage("End time must be after start time");
        });

        When(x => x.Dto.TimeZone != null, () => {
            RuleFor(x => x.Dto.TimeZone)
                .Must(timeZone => _timeZoneService.ValidateTimeZone(timeZone!))
                .WithMessage("Invalid timezone");
        });

        When(x => x.Dto.Location != null, () => {
            RuleFor(x => x.Dto.Location)
                .MaximumLength(500).WithMessage("Location cannot exceed 500 characters");
        });

        When(x => x.Dto.AddMembers != null, () => {
            RuleFor(x => x.Dto.AddMembers)
                .Must(members => members!.Count <= 100)
                .WithMessage("Cannot add more than 100 members at once")
                .MustAsync(async (members, ct) => {
                    foreach (var memberId in members!)
                    {
                        var member = await _unitOfWork.OrganizationMembers.GetByUserId(memberId, false, ct);
                        if (member == null) return false;
                    }
                    return true;
                }).WithMessage("One or more invalid member IDs in AddMembers");
        });

        When(x => x.Dto.RemoveMembers != null, () => {
            RuleFor(x => x.Dto.RemoveMembers)
                .MustAsync(async (cmd, members, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(cmd.Dto.MeetingId, ct);
                    return members!.All(m => meeting!.MeetingMembers.Any(mm => 
                        mm.OrganizationMember_IdOrganizationMember == m));
                }).WithMessage("One or more members to remove are not part of the meeting");
        });

        When(x => x.Dto.RecurringPattern != null, () => {
            RuleFor(x => x.Dto.RecurringPattern)
                .SetValidator(new RecurringMeetingPatternValidator()!)
                .DependentRules(() => {
                    RuleFor(x => x).MustAsync(async (cmd, ct) => {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                        return meeting!.Status == MeetingStatus.Scheduled;
                    }).WithMessage("Cannot update recurring pattern of a meeting that has already started");
                });
        });

        When(x => x.Dto.ReminderTime.HasValue, () => {
            RuleFor(x => x)
                .MustAsync(async (cmd, ct) => {
                    try {
                        var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.Dto.MeetingId, ct);
                        if (meeting == null) return false;

                        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
                            cmd.Dto.TimeZone ?? meeting.TimeZoneId);
                        
                        var reminderTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                            DateTime.SpecifyKind(cmd.Dto.ReminderTime!.Value, DateTimeKind.Unspecified),
                            timeZoneInfo);

                        return reminderTimeUtc > DateTime.UtcNow;
                    }
                    catch {
                        return false;
                    }
                })
                .WithMessage("Reminder time must be in the future");
        });
    }
} 