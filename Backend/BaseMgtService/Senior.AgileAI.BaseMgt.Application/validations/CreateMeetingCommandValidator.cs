using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class CreateMeetingCommandValidator : AbstractValidator<CreateMeetingCommand>
{
    private readonly ITimeZoneService _timeZoneService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAudioStorageService _audioStorage;

    public CreateMeetingCommandValidator(ITimeZoneService timeZoneService, IUnitOfWork unitOfWork, IAudioStorageService audioStorage)
    {
        _timeZoneService = timeZoneService;
        _unitOfWork = unitOfWork;
        _audioStorage = audioStorage;

        ClassLevelCascadeMode = CascadeMode.Stop;
        RuleLevelCascadeMode = CascadeMode.Stop;

        RuleFor(x => x.Dto.Title)
            .NotEmpty().WithMessage("Title is required")
            .MaximumLength(200).WithMessage("Title cannot exceed 200 characters");

        RuleFor(x => x.Dto.Goal)
            .MaximumLength(1000).WithMessage("Goal cannot exceed 1000 characters");

        RuleFor(x => x.Dto.ProjectId)
            .NotEmpty().WithMessage("Project ID is required")
            .MustAsync(async (projectId, ct) => {
                var project = await _unitOfWork.Projects.GetByIdAsync(projectId,ct,false);
                return project != null;
            }).WithMessage("Invalid project ID")
            .DependentRules(() => {
                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var hasAccess = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                        cmd.Dto.ProjectId,
                        cmd.UserId,
                        ct);
                    return hasAccess?.Meetings >= PrivilegeLevel.Write;
                }).WithMessage("You don't have permission to create meetings in this project");
            });

        RuleFor(x => x.Dto.TimeZone)
            .NotEmpty().WithMessage("TimeZone is required")
            .Must((cmd, timeZone) => {
                Console.WriteLine($"Validating timezone: {timeZone}");
                return _timeZoneService.ValidateTimeZone(timeZone);
            })
            .WithMessage("Invalid timezone");

        RuleFor(x => x.Dto.StartTime)
            .NotEmpty().WithMessage("Start time is required")
            .Must((cmd, startTime) => {
                try {
                    var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(cmd.Dto.TimeZone);
                    var clientLocalTime = DateTime.SpecifyKind(startTime, DateTimeKind.Unspecified);
                    var utcStartTime = TimeZoneInfo.ConvertTimeToUtc(clientLocalTime, timeZoneInfo);
                    
                    if (cmd.Dto.Type == MeetingType.Done) {
                        return true; // Allow past dates for Done meetings
                    }
                    
                    return utcStartTime > DateTime.UtcNow.AddMinutes(-5);
                }
                catch (Exception) {
                    return false;
                }
            })
            .WithMessage("Meeting must start in the future for non-Done meetings");

        RuleFor(x => x.Dto.EndTime)
            .NotEmpty().WithMessage("End time is required")
            .Must((cmd, endTime) => {
                try {
                    var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(cmd.Dto.TimeZone);
                    
                    var startLocalTime = DateTime.SpecifyKind(cmd.Dto.StartTime, DateTimeKind.Unspecified);
                    var endLocalTime = DateTime.SpecifyKind(endTime, DateTimeKind.Unspecified);
                    
                    var utcStartTime = TimeZoneInfo.ConvertTimeToUtc(startLocalTime, timeZoneInfo);
                    var utcEndTime = TimeZoneInfo.ConvertTimeToUtc(endLocalTime, timeZoneInfo);
                    
                    return utcEndTime > utcStartTime;
                }
                catch (Exception) {
                    return false;
                }
            })
            .WithMessage("End time must be after start time");

        

        When(x => x.Dto.Type == MeetingType.InPerson, () => {
            RuleFor(x => x.Dto.Location)
                .NotEmpty().WithMessage("Location is required for in-person meetings")
                .MaximumLength(500).WithMessage("Location cannot exceed 500 characters");
        });

        When(x => x.Dto.IsRecurring, () => {
            RuleFor(x => x.Dto.RecurringPattern)
                .NotNull().WithMessage("Recurring pattern is required when IsRecurring is true")
                .SetValidator(new RecurringMeetingPatternValidator()!);
            RuleFor(x => x.Dto.Type)
                .Must(type => type != MeetingType.Done)
                .WithMessage("Done meetings cannot be recurring");
        });

        When(x => x.Dto.Type == MeetingType.Online, () => {
            RuleFor(x => x.Dto.MemberIds)
                .Must(members => members.Any())
                .WithMessage("Online meetings require at least one member");
        });

        When(x => x.Dto.Type == MeetingType.Done, () => {
            RuleFor(x => x.Dto.AudioFile)
                .NotNull().WithMessage("Audio file is required for Done meetings")
                .Must((file) => {
                    return _audioStorage.ValidateAudioFile(file!);
                }).WithMessage("Invalid audio file format or size");
        });

        RuleFor(x => x.Dto.MemberIds)
            .Must(members => members.Count <= 100)
            .WithMessage("Cannot have more than 100 members")
            .MustAsync(async (members, ct) => {
                foreach (var memberId in members)
                {
                    var member = await _unitOfWork.OrganizationMembers.GetByIdAsync(memberId,false,ct);
                    if (member == null) return false;
                }
                return true;
            }).WithMessage("One or more invalid member IDs");

        RuleFor(x => x.Dto.ReminderTime)
            .Must((cmd, reminderTime) => {
                if (reminderTime == null || cmd.Dto.Type == MeetingType.Done) return true;
                
                try {
                    var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(cmd.Dto.TimeZone);
                    var localTime = DateTime.SpecifyKind(reminderTime.Value, DateTimeKind.Unspecified);
                    var utcTime = TimeZoneInfo.ConvertTimeToUtc(localTime, timeZoneInfo);
                    return utcTime > DateTime.UtcNow.AddMinutes(-5); // Allow up to 5 minutes in the past, buffer for processing
                }
                catch (Exception) {
                    return false;
                }
            })
            .WithMessage("Reminder time must be in the future for non-Done meetings");
    }
}

public class RecurringMeetingPatternValidator : AbstractValidator<RecurringMeetingPatternDTO>
{
    public RecurringMeetingPatternValidator()
    {
        RuleFor(x => x.Interval)
            .GreaterThan(0).WithMessage("Interval must be greater than 0")
            .LessThanOrEqualTo(365).WithMessage("Interval cannot exceed 365");

        RuleFor(x => x.RecurringEndDate)
            .NotEmpty().WithMessage("End date is required")
            .Must((pattern, endDate) => {
                try {
                    var utcEndDate = TimeZoneInfo.ConvertTimeToUtc(
                        DateTime.SpecifyKind(endDate, DateTimeKind.Unspecified),
                        TimeZoneInfo.Utc);
                    var utcNow = DateTime.UtcNow;
                    var utcOneYearFromNow = utcNow.AddYears(1);
                    
                    return utcEndDate > utcNow && utcEndDate <= utcOneYearFromNow;
                }
                catch (Exception) {
                    return false;
                }
            })
            .WithMessage("End date must be in the future but not more than a year in advance");

        When(x => x.RecurrenceType == RecurrenceType.Weekly, () => {
            RuleFor(x => x.DaysOfWeek)
                .NotNull().WithMessage("Days of week are required for weekly recurrence")
                .Must(days => days != DaysOfWeek.None)
                .WithMessage("At least one day must be selected for weekly recurrence");
        });
    }
}