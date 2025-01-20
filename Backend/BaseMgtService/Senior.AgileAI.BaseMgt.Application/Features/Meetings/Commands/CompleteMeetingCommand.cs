using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record CompleteMeetingCommand(Guid MeetingId, Guid UserId) : IRequest<bool>; 