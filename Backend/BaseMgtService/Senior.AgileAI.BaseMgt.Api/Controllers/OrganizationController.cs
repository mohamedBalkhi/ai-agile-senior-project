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
        public async Task<ActionResult<ApiResponse<Guid>>> CreateOrganization(CreateOrganizationDTO dto)
        {
            try
            {
                var command = new CreateOrganizationCommand(dto);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<Guid>(200, "Organization created successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new { Message = "Validation failed", Errors = ex.Errors });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "An error occurred while processing your request", Error = ex.Message });
            }
        }


        [Authorize]
        [HttpPost("DeactivateOrganization")]
        public async Task<ActionResult<ApiResponse<bool>>> DeactivateOrganization([FromBody] DeactivateOrganizationCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Organization deactivated successfully", result));
        }


        [Authorize]
        [HttpPost("AddOrgMembers")]
        public async Task<ActionResult<ApiResponse<AddOrgMembersResponseDTO>>> AddOrgMembers(AddOrgMembersDTO dto)
        {
            var userId = GetCurrentUserId();
            var command = new AddOrgMembersCommand(dto, userId);
            var result = await _mediator.Send(command);
            
            var message = result.SuccessCount > 0 
                ? $"Successfully added {result.SuccessCount} member(s)" + (result.FailureCount > 0 ? $", {result.FailureCount} failed" : "")
                : "No members were added";
            
            return Ok(new ApiResponse<AddOrgMembersResponseDTO>(
                result.SuccessCount > 0 ? 200 : 400,
                message,
                result
            ));
        }

        [Authorize]
        [HttpGet("GetOrganizationMembers")]
        public async Task<ActionResult<ApiResponse<List<GetOrgMemberDTO>>>> GetOrganizationMembers()
        {
            var userId = GetCurrentUserId();
            var query = new GetOrganizationMembersQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse<List<GetOrgMemberDTO>>(200, "Organization members fetched successfully", result));
        }

        [Authorize]
        [HttpGet("GetOrganizationProjects")]
        public async Task<ActionResult<ApiResponse<List<GetOrgProjectDTO>>>> GetOrganizationProjects()
        {
            var userId = GetCurrentUserId();
            var query = new GetOrganizationProjectsQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse<List<GetOrgProjectDTO>>(200, "Organization projects fetched successfully", result));
        }

        [Authorize]
        [HttpPost("SetMemberAsAdmin")]
        public async Task<ActionResult<ApiResponse<bool>>> SetMemberAsAdmin([FromQuery] Guid userId, [FromQuery] bool isAdmin)
        {
            var command = new SetMemberAsAdminCommand(userId, isAdmin);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Member got full administrative privileges successfully", result));
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
