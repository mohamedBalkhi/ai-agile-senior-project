using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;

public record GetMeetingAudioQuery(Guid MeetingId, Guid UserId) : IRequest<AudioFileResult>;

public record AudioFileResult
{
    public required Stream Stream { get; init; }
    public required string ContentType { get; init; }
    public required string FileName { get; init; }
} 