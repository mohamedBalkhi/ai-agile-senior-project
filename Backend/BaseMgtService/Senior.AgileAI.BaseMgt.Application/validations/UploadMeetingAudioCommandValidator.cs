using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Validations;

public class UploadMeetingAudioCommandValidator : AbstractValidator<UploadMeetingAudioCommand>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAudioStorageService _audioStorage;

    public UploadMeetingAudioCommandValidator(IUnitOfWork unitOfWork, IAudioStorageService audioStorage)
    {
        _unitOfWork = unitOfWork;
        _audioStorage = audioStorage;

        ClassLevelCascadeMode = CascadeMode.Stop;
        RuleLevelCascadeMode = CascadeMode.Stop;

        RuleFor(x => x.MeetingId)
            .NotEmpty().WithMessage("Meeting ID is required")
            .MustAsync(async (cmd, id, ct) => {
                var meeting = await _unitOfWork.Meetings.GetByIdAsync(id);
                return meeting != null;
            }).WithMessage("Meeting not found")
            .DependentRules(() => {
                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    return meeting?.Type != MeetingType.Online;
                }).WithMessage("Cannot upload audio for online meetings");

                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    return meeting?.CanUploadAudio() ?? false;
                }).WithMessage("Meeting must be in progress or completed to upload audio");

                RuleFor(x => x).MustAsync(async (cmd, ct) => {
                    var meeting = await _unitOfWork.Meetings.GetByIdAsync(cmd.MeetingId);
                    if (meeting == null) return false;

                    var privilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                        meeting.Project_IdProject,
                        cmd.UserId,
                        ct);

                    return meeting.Creator_IdOrganizationMember == cmd.UserId ||
                           (privilege != null && privilege.Meetings >= PrivilegeLevel.Write);
                }).WithMessage("You don't have permission to upload audio for this meeting");
            });

        RuleFor(x => x.AudioFile)
            .NotNull().WithMessage("Audio file is required")
            .DependentRules(() => {
                RuleFor(x => x.AudioFile)
                    .Must((file) => {
                        return _audioStorage.ValidateAudioFile(file);
                    }).WithMessage("Invalid audio file format or size");
            });

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required");
    }
} 