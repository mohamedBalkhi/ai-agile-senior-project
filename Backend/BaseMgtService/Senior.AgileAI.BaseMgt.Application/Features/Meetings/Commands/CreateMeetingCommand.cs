using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record CreateMeetingCommand(CreateMeetingDTO Dto, Guid UserId) : IRequest<Guid>; 