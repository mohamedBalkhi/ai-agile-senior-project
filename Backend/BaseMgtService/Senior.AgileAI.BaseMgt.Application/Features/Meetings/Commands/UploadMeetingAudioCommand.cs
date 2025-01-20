using MediatR;
using Microsoft.AspNetCore.Http;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;

public record UploadMeetingAudioCommand(
    Guid MeetingId, 
    IFormFile AudioFile, 
    Guid UserId) : IRequest<string>; 