using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record ConfirmMeetingAttendanceCommand(
    Guid MeetingId,
    Guid UserId,
    bool IsConfirmed) : IRequest<bool>; 