using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;

public record GetMeetingAIReportQuery(Guid MeetingId, Guid UserId) : IRequest<MeetingAIReportDTO>;
