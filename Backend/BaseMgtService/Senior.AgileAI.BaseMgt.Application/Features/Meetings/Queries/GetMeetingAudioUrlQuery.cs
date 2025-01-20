using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;

public record GetMeetingAudioUrlQuery(Guid MeetingId, Guid UserId) : IRequest<AudioUrlResult>;

public record AudioUrlResult
{
    public required string PreSignedUrl { get; init; }
    public required string FileName { get; init; }
    public required string ContentType { get; init; }
    public required int ExpirationMinutes { get; init; }
} 