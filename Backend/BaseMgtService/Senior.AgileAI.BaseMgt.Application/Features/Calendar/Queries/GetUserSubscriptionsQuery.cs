using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;

public record GetUserSubscriptionsQuery(Guid UserId) : IRequest<List<CalendarSubscriptionDTO>>; 