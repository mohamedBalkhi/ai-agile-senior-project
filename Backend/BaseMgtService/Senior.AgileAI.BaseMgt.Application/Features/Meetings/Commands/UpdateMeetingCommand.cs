using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record UpdateMeetingCommand(UpdateMeetingDTO Dto, Guid UserId) : IRequest<bool>; 