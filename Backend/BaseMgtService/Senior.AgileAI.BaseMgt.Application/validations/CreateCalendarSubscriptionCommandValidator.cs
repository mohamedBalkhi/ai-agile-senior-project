using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class CreateCalendarSubscriptionCommandValidator : AbstractValidator<CreateCalendarSubscriptionCommand>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateCalendarSubscriptionCommandValidator(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;

        ClassLevelCascadeMode = CascadeMode.Stop;
        RuleLevelCascadeMode = CascadeMode.Stop;

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required")
            .MustAsync(async (userId, ct) => {
                var user = await _unitOfWork.Users.GetByIdAsync(userId, ct);
                return user != null;
            }).WithMessage("Invalid user ID");

        RuleFor(x => x.Dto.FeedType)
            .IsInEnum().WithMessage("Invalid feed type");

        RuleFor(x => x.Dto.ExpirationDays)
            .GreaterThan(0).WithMessage("Expiration days must be greater than 0")
            .LessThanOrEqualTo(365).WithMessage("Expiration days cannot exceed 365");

        When(x => x.Dto.FeedType == CalendarFeedType.Project, () => {
            RuleFor(x => x.Dto.ProjectId)
                .NotNull().WithMessage("Project ID is required for project feed type")
                .MustAsync(async (cmd, projectId, ct) => {
                    if (!projectId.HasValue) return false;
                    var project = await _unitOfWork.Projects.GetByIdAsync(projectId.Value, ct);
                    return project != null;
                }).WithMessage("Invalid project ID");
        });

        When(x => x.Dto.FeedType == CalendarFeedType.Series, () => {
            RuleFor(x => x.Dto.RecurringPatternId)
                .NotNull().WithMessage("Recurring pattern ID is required for series feed type")
                .MustAsync(async (cmd, patternId, ct) => {
                    if (!patternId.HasValue) return false;
                    var pattern = await _unitOfWork.RecurringMeetingPatterns
                        .GetByIdAsync(patternId.Value, ct);
                    return pattern != null;
                }).WithMessage("Invalid recurring pattern ID");
        });
    }
} 