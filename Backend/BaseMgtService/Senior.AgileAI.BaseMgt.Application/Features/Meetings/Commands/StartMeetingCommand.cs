using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record StartMeetingCommand(Guid MeetingId, Guid UserId) : IRequest<bool>; 