using Microsoft.AspNetCore.Mvc;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Queries;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MeetingController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ITokenResolver _tokenResolver;

    public MeetingController(IMediator mediator, ITokenResolver tokenResolver)
    {
        _mediator = mediator;
        _tokenResolver = tokenResolver;
    }

    [HttpPost("CreateMeeting")]
    public async Task<ActionResult<ApiResponse<Guid>>> CreateMeeting([FromForm] CreateMeetingDTO dto)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new CreateMeetingCommand(dto, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<Guid>(200, "Meeting created successfully", result));
    }

    [HttpGet("GetProjectMeetings")]
    public async Task<ActionResult<ApiResponse<List<MeetingDTO>>>> GetProjectMeetings(
        [FromQuery] Guid projectId,
        [FromQuery] bool upcomingOnly,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] int pageSize = 10)
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetProjectMeetingsQuery(projectId, userId ?? Guid.Empty, upcomingOnly, fromDate, toDate, pageSize);
        var result = await _mediator.Send(query);
        return Ok(new ApiResponse<GroupedMeetingsResponse>(200, "Meetings retrieved successfully", result));
    }

    [HttpGet("GetMeetingDetails")]
    public async Task<ActionResult<ApiResponse<MeetingDetailsDTO>>> GetMeetingDetails([FromQuery] Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetMeetingDetailsQuery(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(query);
        return Ok(new ApiResponse<MeetingDetailsDTO>(200, "Meeting details retrieved successfully", result));
    }

    [HttpPut("UpdateMeeting")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateMeeting([FromForm] UpdateMeetingDTO dto)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new UpdateMeetingCommand(dto, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Meeting updated successfully", result));
    }

    [HttpDelete("CancelMeeting")]
    public async Task<ActionResult<ApiResponse<bool>>> CancelMeeting([FromQuery] Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new CancelMeetingCommand(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Meeting cancelled successfully", result));
    }

    [HttpPost("{meetingId}/UploadAudio")]
    public async Task<ActionResult<ApiResponse<string>>> UploadAudio(
        Guid meetingId, 
        IFormFile audioFile)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new UploadMeetingAudioCommand(meetingId, audioFile, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<string>(200, "Audio uploaded successfully", result));
    }

    [HttpGet("{meetingId}/Audio")]
    public async Task<ActionResult> GetAudio(Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetMeetingAudioQuery(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(query);
        
        return File(result.Stream, result.ContentType, result.FileName);
    }

    [HttpGet("{meetingId}/AIReport")]
    public async Task<ActionResult<ApiResponse<MeetingAIReportDTO>>> GetMeetingAIReport(Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetMeetingAIReportQuery(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(query);
        return Ok(new ApiResponse<MeetingAIReportDTO>(200, "AI report retrieved successfully", result));
    }

    [HttpPost("{meetingId}/Start")]
    public async Task<ActionResult<ApiResponse<bool>>> StartMeeting(Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new StartMeetingCommand(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Meeting started successfully", result));
    }

    [HttpPost("{meetingId}/Complete")]
    public async Task<ActionResult<ApiResponse<bool>>> CompleteMeeting(Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new CompleteMeetingCommand(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Meeting completed successfully", result));
    }

    [HttpPost("{meetingId}/ModifyRecurring")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<bool>>> ModifyRecurringMeeting(
        Guid meetingId,
        [FromBody] ModifyRecurringMeetingDto Dto)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new ModifyRecurringMeetingCommand(
            meetingId,
            Dto,
            userId ?? Guid.Empty);

        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Meeting modified successfully", result));
    }

    [HttpPost("{meetingId}/Confirm")]
    public async Task<ActionResult<ApiResponse<bool>>> ConfirmAttendance(
        Guid meetingId,
        [FromBody] bool isConfirmed)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new ConfirmMeetingAttendanceCommand(meetingId, userId ?? Guid.Empty, isConfirmed);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, 
            $"Meeting attendance {(isConfirmed ? "confirmed" : "declined")} successfully", 
            result));
    }

    [HttpGet("{meetingId}/AudioUrl")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<AudioUrlResult>>> GetAudioUrl(Guid meetingId)
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetMeetingAudioUrlQuery(meetingId, userId ?? Guid.Empty);
        var result = await _mediator.Send(query);
        return Ok(new ApiResponse<AudioUrlResult>(200, "Audio URL generated successfully", result));
    }

} 