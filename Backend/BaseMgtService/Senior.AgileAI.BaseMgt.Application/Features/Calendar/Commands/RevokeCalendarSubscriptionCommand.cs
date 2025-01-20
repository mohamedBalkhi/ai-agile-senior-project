using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;

public record RevokeCalendarSubscriptionCommand(
    string Token,
    Guid UserId) : IRequest<bool>; 