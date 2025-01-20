using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;

public record GetProjectMeetingsQuery(
    Guid ProjectId, 
    Guid UserId,
    bool UpcomingOnly,
    DateTime? FromDate,    // For pagination/virtual scrolling
    DateTime? ToDate,      // For pagination/virtual scrolling
    int PageSize) : IRequest<GroupedMeetingsResponse>; 