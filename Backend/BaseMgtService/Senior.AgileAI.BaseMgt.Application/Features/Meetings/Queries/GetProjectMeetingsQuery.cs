using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;

public record GetProjectMeetingsQuery(
    Guid ProjectId,
    Guid UserId,
    string TimeZoneId,
    bool IsUpcoming,
    DateTime? ReferenceDate,
    int PageSize,
    string? LastMeetingId) : IRequest<GroupedMeetingsResponse>;