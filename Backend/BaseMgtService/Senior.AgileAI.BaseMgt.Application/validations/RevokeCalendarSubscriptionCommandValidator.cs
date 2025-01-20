using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class RevokeCalendarSubscriptionCommandValidator : AbstractValidator<RevokeCalendarSubscriptionCommand>
{
    private readonly IUnitOfWork _unitOfWork;

    public RevokeCalendarSubscriptionCommandValidator(IUnitOfWork unitOfWork)
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

        RuleFor(x => x.Token)
            .NotEmpty().WithMessage("Token is required")
            .MustAsync(async (cmd, token, ct) => {
                var subscription = await _unitOfWork.CalendarSubscriptions
                    .GetByTokenAsync(token, ct);
                return subscription != null;
            }).WithMessage("Invalid subscription token")
            .MustAsync(async (cmd, token, ct) => {
                var subscription = await _unitOfWork.CalendarSubscriptions
                    .GetByTokenAsync(token, ct);
                return subscription?.User_IdUser == cmd.UserId;
            }).WithMessage("You don't have permission to revoke this subscription");
    }
} 