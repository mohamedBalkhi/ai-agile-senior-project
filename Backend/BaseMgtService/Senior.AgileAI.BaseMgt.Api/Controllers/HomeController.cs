using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Features.Country.Queries;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;
using Senior.AgileAI.BaseMgt.Application.Features.Home.Queries;



namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HomeController : ControllerBase
    {
        private readonly IMediator _mediator;
        private readonly ITokenResolver _tokenResolver;

        public HomeController(IMediator mediator, ITokenResolver tokenResolver)
        {
            _mediator = mediator;
            _tokenResolver = tokenResolver;
        }
        [Authorize]
        [HttpGet(Name = "GetHome")]
        public async Task<ActionResult<ApiResponse<HomeDTO>>> GetHome()
        {
            try
            {
                var userId = _tokenResolver.ExtractUserId();
                var command = new GetHomeQuery
                {
                    UserId = userId ?? Guid.Empty
                };
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse(200, "Home Data fetched successfully", result));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [Authorize("SuperAdmin")]
        [HttpGet("GetAdminDashBoard")]
        public async Task<ActionResult<ApiResponse<AdminDashboardDto>>> GetAdminDashboard()
        {
            try
            {
                var command = new GetAdminDashboard();
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse(200, "Admin dashboard data fetched successfully", result));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

    }
}
