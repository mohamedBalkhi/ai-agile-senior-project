using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class UploadMeetingAudioCommandHandler : IRequestHandler<UploadMeetingAudioCommand, string>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAudioStorageService _audioStorage;
    private readonly IProjectAuthorizationHelper _authHelper;

    public UploadMeetingAudioCommandHandler(
        IUnitOfWork unitOfWork,
        IAudioStorageService audioStorage,
        IProjectAuthorizationHelper authHelper)
    {
        _unitOfWork = unitOfWork;
        _audioStorage = audioStorage;
        _authHelper = authHelper;
    }

    public async Task<string> Handle(UploadMeetingAudioCommand request, CancellationToken cancellationToken)
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
            PrivilegeLevel.Write,
            cancellationToken);

        if (!hasAccess && meeting.Creator_IdOrganizationMember != request.UserId)
        {
            throw new UnauthorizedAccessException("You don't have permission to upload audio for this meeting");
        }

        // Validate meeting type and status
        if (meeting.Type == MeetingType.Online)
        {
            throw new InvalidOperationException("Cannot upload audio for online meetings");
        }

        // Validate audio file
        if (!_audioStorage.ValidateAudioFile(request.AudioFile))
        {
            throw new InvalidOperationException("Invalid audio file");
        }

        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Upload audio file
            var audioUrl = await _audioStorage.UploadAudioAsync(
                meeting.Id,
                request.AudioFile,
                cancellationToken);

            // Update meeting
            meeting.AudioUrl = audioUrl;
            meeting.AudioStatus = AudioStatus.Available;
            meeting.AudioSource = AudioSource.Upload;
            meeting.AudioUploadedAt = DateTime.UtcNow;
            if (meeting.Status != MeetingStatus.Completed)
            {
                meeting.Complete();
            }
            
            // Reset AI processing status to ensure it gets picked up by the worker
            meeting.AIProcessingStatus = AIProcessingStatus.NotStarted;
            meeting.AIProcessingToken = null;
            meeting.AIReport = null;
            meeting.AIProcessedAt = null;
            _unitOfWork.Meetings.Update(meeting);
            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            return audioUrl;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }
} 