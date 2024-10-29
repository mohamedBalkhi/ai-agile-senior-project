using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Common;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;


namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrganizationController : ControllerBase
    {
        private readonly IMediator _mediator;
        public OrganizationController(IMediator mediator)
        {
            _mediator = mediator;
        }


        [HttpPost("CreateOrganization")]
        public async Task<ActionResult<ApiResponse>> CreateOrganization(CreateOrganizationDTO dto)
        {
            try
            {
                var command = new CreateOrganizationCommand(dto);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse(200, "Organization created successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }


        [Authorize]
        [HttpPost("DeactivateOrganization")]
        public async Task<ActionResult<ApiResponse>> DeactivateOrganization([FromBody] DeactivateOrganizationCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Organization deactivated successfully", result));
        }


        [Authorize]
        [HttpPost("AddOrgMember")]
        public async Task<ActionResult<ApiResponse>> AddOrgMember(OrgMemberDTO dto)
        {
            var userId = GetCurrentUserId();
            Console.WriteLine(userId);
            var command = new AddOrgMember(dto, userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Organization member added successfully", result));
        }

        [Authorize]
        [HttpGet("GetOrganizationMembers")]
        public async Task<ActionResult<ApiResponse>> GetOrganizationMembers()
        {
            var userId = GetCurrentUserId();
            var query = new GetOrganizationMembersQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Organization members fetched successfully", result));
        }

        [Authorize]
        [HttpGet("GetOrganizationProjects")]
        public async Task<ActionResult<ApiResponse>> GetOrganizationProjects()
        {
            var userId = GetCurrentUserId();
            var query = new GetOrganizationProjectsQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Organization projects fetched successfully", result));
        }

        [Authorize]
        [HttpPost("SetMemberAsAdmin")]
        public async Task<ActionResult<ApiResponse>> SetMemberAsAdmin([FromBody] Guid userId)
        {
            var command = new SetMemberAsAdminCommand(userId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Member got full administrative privileges successfully", result));
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
