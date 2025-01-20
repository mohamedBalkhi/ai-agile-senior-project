using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using System.IO;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.QueryHandlers;

public class GetMeetingAudioQueryHandler : IRequestHandler<GetMeetingAudioQuery, AudioFileResult>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAudioStorageService _audioStorage;
    private readonly IProjectAuthorizationHelper _authHelper;

    public GetMeetingAudioQueryHandler(
        IUnitOfWork unitOfWork,
        IAudioStorageService audioStorage,
        IProjectAuthorizationHelper authHelper)
    {
        _unitOfWork = unitOfWork;
        _audioStorage = audioStorage;
        _authHelper = authHelper;
    }

    private string GetContentType(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return extension switch
        {
            ".mp3" => "audio/mpeg",
            ".wav" => "audio/wav",
            ".m4a" => "audio/mp4",
            _ => "application/octet-stream"  // fallback
        };
    }

    public async Task<AudioFileResult> Handle(GetMeetingAudioQuery request, CancellationToken cancellationToken)
    {
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken);
        if (meeting == null)
        {
            throw new NotFoundException("Meeting not found");
        }

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            meeting.Project_IdProject,
            ProjectAspect.Meetings,
            PrivilegeLevel.Read,
            cancellationToken);

        if (!hasAccess)
        {
            throw new UnauthorizedAccessException("You don't have permission to access this meeting's audio");
        }

        if (string.IsNullOrEmpty(meeting.AudioUrl))
        {
            throw new NotFoundException("No audio file found for this meeting");
        }

        var audioStream = await _audioStorage.GetAudioAsync(meeting.AudioUrl, cancellationToken);
        var fileName = Path.GetFileName(meeting.AudioUrl);
        
        return new AudioFileResult
        {
            Stream = audioStream,
            ContentType = GetContentType(fileName),
            FileName = fileName
        };
    }
} 