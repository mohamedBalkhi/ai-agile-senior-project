using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;

public record CreateCalendarSubscriptionCommand(
    CreateCalendarSubscriptionDTO Dto,
    Guid UserId) : IRequest<CalendarSubscriptionDTO>; 