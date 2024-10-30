using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Common;
using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;

using Senior.AgileAI.BaseMgt.Application.Common.Utils;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ITokenResolver _tokenResolver;

    public AuthController(IMediator mediator, ILogger<AuthController> logger, ITokenResolver tokenResolver)
    {
        _mediator = mediator;
        _tokenResolver = tokenResolver;
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResult>>> Login([FromBody] LoginCommand command)
    {
        try
        {
            var result = await _mediator.Send(command);
            SetRefreshTokenCookie(result.RefreshToken);

            return Ok(new ApiResponse(
                200,
                "Login successful",
                new { AccessToken = result.AccessToken }
            ));
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ApiResponse(
                400,
                "Validation failed",
                ex.Errors
            ));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new ApiResponse(
                401,
                "Authentication failed",
                ex.Message
            ));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse(
                500,
                "An error occurred while processing your request",
                ex.Message
            ));
        }
    }


    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResult>> Refresh()
    {
        var refreshToken = Request.Cookies["refreshToken"];

        if (string.IsNullOrEmpty(refreshToken))
        {
            return BadRequest("Invalid token");
        }

        var command = new RefreshTokenCommand { RefreshToken = refreshToken };
        var result = await _mediator.Send(command);

        return Ok(new { AccessToken = result.AccessToken });
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        var refreshToken = Request.Cookies["refreshToken"];
        if (string.IsNullOrEmpty(refreshToken))
        {
            return BadRequest("Invalid token");
        }

        await _mediator.Send(new LogoutCommand { RefreshToken = refreshToken });
        Response.Cookies.Delete("refreshToken");
        return Ok();
    }

    [Authorize]
    [HttpGet("test")]
    public ActionResult<object> Test()
    {
        var userId = _tokenResolver.ExtractUserId();
        return Ok(new ApiResponse(200, "Test successful", userId));
    }


    [HttpPost("signup")]
    public async Task<ActionResult<ApiResponse<Guid>>> SignUp([FromBody] SignUpDTO dto)
    {
        try
        {
            var command = new SignUpCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<Guid>(200, "Signup successful", result));
        }
        catch (ValidationException ex)
        {

            return BadRequest(new
            {
                Message = "Validation failed",
                Errors = ex.Errors
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                Message = "An error occurred while processing your request",
                Error = ex.Message
            });
        }
    }

    [HttpPost("VerifyEmail")]
    public async Task<ActionResult<ApiResponse<bool>>> VerifyEmail(VerifyEmailDTO dto)
    {
        var command = new VerifyEmailCommand(dto);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Email verified successfully", result));

    }

    // if the user wants to resend the code, we need to send the code to the user's email.
    [HttpPost("ResendCode")]
    public async Task<ActionResult<ApiResponse<Guid>>> ResendCode([FromQuery] Guid userId)
    {
        try
        {
            var command = new ResendCodeCommand(userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<Guid>(200, "Code resent successfully", result));
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ApiResponse(400, "Validation failed", ex.Errors));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse(500, "An error occurred while processing your request", ex.Message));
        }
    }

    [Authorize]
    [HttpPut("CompleteProfile")]
    public async Task<ActionResult<ApiResponse<bool>>> CompleteProfile(CompleteProfileDTO dto)
    {
        var userId = GetCurrentUserId(); //the user should be loged in using their email with the  default password
        var command = new CompleteProfileCommand(dto, userId);
        var result = await _mediator.Send(command);
        return Ok(new ApiResponse<bool>(200, "Profile completed successfully", result));
    }

    [Authorize("Admin")] // Add this attribute to endpoints that need admin access
    [HttpGet("admin-only")]
    public ActionResult<object> AdminOnlyEndpoint()
    {
        var userId = _tokenResolver.ExtractUserId();
        return Ok(new ApiResponse(200, "Admin access successful", userId));
    }




    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Expires = DateTime.UtcNow.AddDays(100),
            SameSite = SameSiteMode.Strict,
            Secure = false // TODO: Change to true when deploying to production
        };
        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
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
