using System.Security.Claims;
using FluentValidation;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.Commands;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly IMediator _mediator;

    public NotificationsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [Authorize]
    [HttpPost("Subscribe")]
    public async Task<ActionResult<ApiResponse<bool>>> Subscribe([FromBody] NotificationTokenDTO dto)
    {
        try 
        {
            var userId = GetCurrentUserId();
            var command = new SubscribeTokenCommand(dto, userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Token subscribed successfully", result));
        }
        catch (ValidationException ex)
        {
            var errors = ex.Errors.ToDictionary(
                x => x.PropertyName,
                x => x.ErrorMessage
            );
            
            return BadRequest(new ApiResponse<bool>
            {
                StatusCode = 400,
                Message = "Validation failed",
                Data = false,
                Errors = errors
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<bool>
            {
                StatusCode = 500,
                Message = "An error occurred while processing your request",
                Data = false,
                Error = ex.Message
            });
        }
    }

    [Authorize]
    [HttpPost("Unsubscribe")]
    public async Task<ActionResult<ApiResponse<bool>>> Unsubscribe([FromBody] NotificationTokenDTO dto)
    {
        try 
        {
            var userId = GetCurrentUserId();
            var command = new UnsubscribeTokenCommand(dto, userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Token unsubscribed successfully", result));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<bool>
            {
                StatusCode = 500,
                Message = "An error occurred while processing your request",
                Data = false,
                Error = ex.Message
            });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
        {
            throw new UnauthorizedAccessException("User ID not found in token");
        }
        return userId;
    }
} 