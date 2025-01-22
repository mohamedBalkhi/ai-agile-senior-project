using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class GenerateMeetingTokenCommandHandler : IRequestHandler<GenerateMeetingTokenCommand, string>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IOnlineMeetingService _onlineMeetingService;

    public GenerateMeetingTokenCommandHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper,
        IOnlineMeetingService onlineMeetingService)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
        _onlineMeetingService = onlineMeetingService;
    }

    public async Task<string> Handle(GenerateMeetingTokenCommand request, CancellationToken cancellationToken)
    {
        var member = await _unitOfWork.OrganizationMembers.GetByUserId(request.UserId);
        if (member == null)
        {
            throw new NotFoundException("Member not found");
        }

        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken);
        if (meeting == null)
        {
            throw new NotFoundException("Meeting not found");
        }

        // Check if user is a member of the meeting
        var meetingMember = meeting.MeetingMembers.FirstOrDefault(m => 
            m.OrganizationMember_IdOrganizationMember == member.Id);

        if (meetingMember == null && meeting.Creator_IdOrganizationMember != member.Id)
        {
            throw new UnauthorizedAccessException("You are not a member of this meeting");
        }

        // Check if meeting is online and active
        if (meeting.Type != MeetingType.Online)
        {
            throw new InvalidOperationException("Meeting is not an online meeting");
        }

        if (meeting.Status != MeetingStatus.InProgress)
        {
            throw new InvalidOperationException("Meeting is not in progress");
        }

        if (string.IsNullOrEmpty(meeting.LiveKitRoomName))
        {
            throw new InvalidOperationException("Meeting room not created");
        }

    

        // Generate token with member metadata
        var token = await _onlineMeetingService.GenerateTokenAsync(
            meeting.LiveKitRoomName,
            request.UserId.ToString(),
            new Dictionary<string, string>
            {
                { "memberId", request.UserId.ToString() },
                { "name", member.User?.FUllName ?? "Unknown" },
                { "email", member.User?.Email ?? "" },
                { "isCreator", (meeting.Creator_IdOrganizationMember == request.UserId).ToString().ToLower() },
                { "isManager", member.IsManager.ToString().ToLower() },
                { "hasAdminPrivilege", member.HasAdministrativePrivilege.ToString().ToLower() }
            },
            cancellationToken);

        return token;
    }
} 