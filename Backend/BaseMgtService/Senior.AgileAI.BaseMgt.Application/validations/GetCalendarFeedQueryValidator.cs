using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class GetCalendarFeedQueryValidator : AbstractValidator<GetCalendarFeedQuery>
{
    private readonly IUnitOfWork _unitOfWork;

    public GetCalendarFeedQueryValidator(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;

        RuleFor(x => x.Token)
            .NotEmpty().WithMessage("Token is required")
            .MustAsync(async (token, ct) => {
                var subscription = await _unitOfWork.CalendarSubscriptions
                    .GetByTokenAsync(token, ct);
                return subscription != null;
            }).WithMessage("Invalid subscription token")
            .MustAsync(async (token, ct) => {
                var subscription = await _unitOfWork.CalendarSubscriptions
                    .GetByTokenAsync(token, ct);
                return subscription?.IsActive == true;
            }).WithMessage("Subscription is not active")
            .MustAsync(async (token, ct) => {
                var subscription = await _unitOfWork.CalendarSubscriptions
                    .GetByTokenAsync(token, ct);
                return subscription?.ExpiresAt > DateTime.UtcNow;
            }).WithMessage("Subscription has expired");
    }
} 