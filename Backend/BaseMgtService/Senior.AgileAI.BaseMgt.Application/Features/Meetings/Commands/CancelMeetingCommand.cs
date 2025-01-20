using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record CancelMeetingCommand(Guid MeetingId, Guid UserId) : IRequest<bool>; 