using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.Test.Queries;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResult>> Login([FromBody] LoginCommand command)
    {
        var result = await _mediator.Send(command);
        SetRefreshTokenCookie(result.RefreshToken);
        return Ok(new { AccessToken = result.AccessToken });
    }
    [HttpGet("test")]
    public async Task<IActionResult> Test()
    {
        var result = await _mediator.Send(new TestQuery());
        return Ok(result);
    }
    [HttpGet("test11")]
    public async Task<IActionResult> Test11()
    {
        var result = await _mediator.Send(new TestQuery(true));
        return Ok(result);
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
}