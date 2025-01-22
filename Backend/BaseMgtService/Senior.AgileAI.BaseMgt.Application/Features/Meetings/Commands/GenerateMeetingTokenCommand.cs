using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record GenerateMeetingTokenCommand : IRequest<string>
{
    public required Guid MeetingId { get; init; }
    public required Guid UserId { get; init; }  // User ID
} 