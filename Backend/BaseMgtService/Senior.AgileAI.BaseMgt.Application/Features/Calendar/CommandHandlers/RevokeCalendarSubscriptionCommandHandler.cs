using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.CommandHandlers;

public class RevokeCalendarSubscriptionCommandHandler 
    : IRequestHandler<RevokeCalendarSubscriptionCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;

    public RevokeCalendarSubscriptionCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<bool> Handle(
        RevokeCalendarSubscriptionCommand request, 
        CancellationToken cancellationToken)
    {
        var subscription = await _unitOfWork.CalendarSubscriptions
            .GetByTokenAsync(request.Token, cancellationToken);

        if (subscription == null || subscription.User_IdUser != request.UserId)
            return false;

        subscription.IsActive = false;
        _unitOfWork.CalendarSubscriptions.Update(subscription);
        await _unitOfWork.CompleteAsync();
        return true;
    }
} 