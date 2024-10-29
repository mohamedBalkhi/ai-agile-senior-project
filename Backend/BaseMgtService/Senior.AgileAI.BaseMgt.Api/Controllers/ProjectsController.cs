using Microsoft.AspNetCore.Mvc;
using MediatR;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Common;

namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProjectsController : ControllerBase
    {
        private readonly IMediator _mediator;

        public ProjectsController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [Authorize]
        [HttpPost("CreateProject")]
        public async Task<ActionResult<ApiResponse>> CreateProject(CreateProjectDTO dto)
        {
            var userId = GetCurrentUserId();
            var command = new CreateProjectCommand(dto, userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Project created successfully", result));
        }

        [Authorize]
        [HttpPost("AssignMember")]
        public async Task<ActionResult<ApiResponse>> AssignMember(AssignMemberDTO dto)
        {
            var userId = GetCurrentUserId();
            var command = new AssignMemberCommand(dto, userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Member assigned to project successfully", result));
        }

        [Authorize]
        [HttpGet("GetProjectMembers")]
        public async Task<ActionResult<ApiResponse>> GetProjectMembers([FromBody] Guid projectId)
        {
            var userId = GetCurrentUserId();
            var query = new GetProjectMembersQuery(projectId, userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Project members retrieved successfully", result));
        }

        [Authorize]
        [HttpGet("GetMemberPrivileges")]
        public async Task<ActionResult<ApiResponse>> GetMemberPrivileges([FromBody] Guid projectId)
        {
            var memberId = GetCurrentUserId();
            var query = new GetMemberPrivilegesQuery(projectId, memberId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Member privileges retrieved successfully", result));
        }

        [Authorize]
        [HttpGet("GetProjectInfo")]
        public async Task<ActionResult<ApiResponse>> GetProjectInfo([FromBody] Guid projectId)
        {
            var userId = GetCurrentUserId();
            var query = new GetProjectInfoQuery(projectId, userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Project info retrieved successfully", result));
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
}