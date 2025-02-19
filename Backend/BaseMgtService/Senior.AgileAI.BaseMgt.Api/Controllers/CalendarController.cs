using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;
using Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CalendarController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ITokenResolver _tokenResolver;

    public CalendarController(
        IMediator mediator,
        ITokenResolver tokenResolver)
    {
        _mediator = mediator;
        _tokenResolver = tokenResolver;
    }

    /// <summary>
    /// Creates a new calendar subscription for the authenticated user
    /// </summary>
    [HttpPost("CreateSubscription")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<CalendarSubscriptionDTO>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<CalendarSubscriptionDTO>>> CreateSubscription(
        [FromBody] CreateCalendarSubscriptionDTO dto)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new CreateCalendarSubscriptionCommand(dto, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        
        return Ok(new ApiResponse<CalendarSubscriptionDTO>(
            StatusCodes.Status200OK, 
            "Calendar subscription created successfully", 
            result));
    }

    /// <summary>
    /// Gets all active calendar subscriptions for the authenticated user
    /// </summary>
    [HttpGet("GetSubscriptions")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<List<CalendarSubscriptionDTO>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<List<CalendarSubscriptionDTO>>>> GetSubscriptions()
    {
        var userId = _tokenResolver.ExtractUserId();
        var query = new GetUserSubscriptionsQuery(userId ?? Guid.Empty);
        var result = await _mediator.Send(query);
        
        return Ok(new ApiResponse<List<CalendarSubscriptionDTO>>(
            StatusCodes.Status200OK, 
            "Calendar subscriptions retrieved successfully", 
            result));
    }

    /// <summary>
    /// Revokes a specific calendar subscription
    /// </summary>
    [HttpDelete("RevokeSubscription/{token}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<bool>>> RevokeSubscription(string token)
    {
        var userId = _tokenResolver.ExtractUserId();
        var command = new RevokeCalendarSubscriptionCommand(token, userId ?? Guid.Empty);
        var result = await _mediator.Send(command);
        
        if (!result)
        {
            return BadRequest(new ApiResponse<bool>(
                StatusCodes.Status400BadRequest, 
                "Failed to revoke subscription"));
        }
        
        return Ok(new ApiResponse<bool>(
            StatusCodes.Status200OK, 
            "Calendar subscription revoked successfully", 
            true));
    }

    /// <summary>
    /// Gets the iCalendar feed for a specific subscription token
    /// </summary>
    [HttpGet("GetCalendarFeed/{token}/{*timeZoneId}")]
    [AllowAnonymous]
    [Produces("text/calendar")]
    [ProducesResponseType(typeof(FileContentResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetCalendarFeed(string token, string timeZoneId)
    {
        // Decode the URL-encoded timezone
        timeZoneId = Uri.UnescapeDataString(timeZoneId);

        if (string.IsNullOrEmpty(timeZoneId))
        {
            return BadRequest(new ApiResponse<string>(
                StatusCodes.Status400BadRequest,
                "TimeZone ID is required"));
        }

        var query = new GetCalendarFeedQuery(token, timeZoneId);
        var result = await _mediator.Send(query);
        if (string.IsNullOrEmpty(result))
        {
            return BadRequest(new ApiResponse<string>(
                StatusCodes.Status400BadRequest, 
                "Failed to generate calendar feed"));
        }
        
        return File(
            System.Text.Encoding.UTF8.GetBytes(result),
            "text/calendar",
            "calendar.ics");
    }
} 