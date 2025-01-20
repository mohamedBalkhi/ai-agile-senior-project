using MediatR;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.QueryHandlers;

public class GetMeetingAIReportQueryHandler : IRequestHandler<GetMeetingAIReportQuery, MeetingAIReportDTO>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IProjectAuthorizationHelper _authHelper;

    public GetMeetingAIReportQueryHandler(
        IUnitOfWork unitOfWork,
        IProjectAuthorizationHelper authHelper)
    {
        _unitOfWork = unitOfWork;
        _authHelper = authHelper;
    }

    public async Task<MeetingAIReportDTO> Handle(GetMeetingAIReportQuery request, CancellationToken cancellationToken)
    {
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(request.MeetingId, cancellationToken)
            ?? throw new NotFoundException("Meeting not found");

        // Check authorization
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            meeting.Project_IdProject,
            ProjectAspect.Meetings,
            PrivilegeLevel.Read,
            cancellationToken);

        if (!hasAccess && meeting.Creator_IdOrganizationMember != request.UserId)
        {
            throw new UnauthorizedAccessException("You don't have permission to view this meeting's AI report");
        }

        // If processing hasn't started or failed
        if (meeting.AIProcessingStatus == AIProcessingStatus.NotStarted ||
            meeting.AIProcessingStatus == AIProcessingStatus.Failed)
        {
            return new MeetingAIReportDTO
            {
                ProcessingStatus = meeting.AIProcessingStatus,
                ProcessedAt = null
            };
        }

        // If processing is ongoing
        if (meeting.AIProcessingStatus == AIProcessingStatus.OnQueue ||
            meeting.AIProcessingStatus == AIProcessingStatus.Processing)
        {
            return new MeetingAIReportDTO
            {
                ProcessingStatus = meeting.AIProcessingStatus,
                ProcessedAt = null
            };
        }

        // If processing is complete but no report (shouldn't happen, but handle it)
        if (meeting.AIReport == null)
        {
            throw new InvalidOperationException("Meeting marked as processed but no report found");
        }

        // Return the complete report
        return new MeetingAIReportDTO
        {
            Transcript = meeting.AIReport.Transcript,
            Summary = meeting.AIReport.Summary,
            KeyPoints = meeting.AIReport.KeyPoints,
            MainLanguage = meeting.AIReport.MainLanguage,
            ProcessingStatus = meeting.AIProcessingStatus,
            ProcessedAt = meeting.AIProcessedAt
        };
    }
}
