using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Common;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.IO;

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
        public async Task<ActionResult<ApiResponse<Guid>>> CreateOrganization([FromForm] CreateOrganizationDTO dto)
        {
            try
            {
                if (dto.LogoFile != null)
                {
                    // Validate file
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                    var extension = Path.GetExtension(dto.LogoFile.FileName).ToLowerInvariant();
                    
                    if (!allowedExtensions.Contains(extension))
                    {
                        return BadRequest(new ApiResponse<Guid>(400, "Invalid file type. Only jpg, jpeg, and png files are allowed.", Guid.Empty));
                    }

                    if (dto.LogoFile.Length > 5 * 1024 * 1024) // 5MB limit
                    {
                        return BadRequest(new ApiResponse<Guid>(400, "File size exceeds 5MB limit.", Guid.Empty));
                    }
                }

                var command = new CreateOrganizationCommand(dto);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<Guid>(200, "Organization created successfully", result));
            }
            catch (ValidationException ex)
            {
                var errors = ex.Errors.ToDictionary(
                    error => error.PropertyName,
                    error => error.ErrorMessage
                );
                return BadRequest(new ApiResponse<Guid>(400, "Validation failed", Guid.Empty, errors: errors));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<Guid>(500, "An error occurred while processing your request", Guid.Empty) { Error = ex.Message });
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
        public async Task<ActionResult<ApiResponse<List<GetOrgMemberDTO>>>> GetOrganizationMembers([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10, [FromQuery] bool? isActiveFilter = null)
        {
            var userId = GetCurrentUserId();
            var query = new GetOrganizationMembersQuery(userId, pageNumber, pageSize, isActiveFilter);
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

        [Authorize]
        [HttpPost("DeActivateMember")]
        public async Task<ActionResult<ApiResponse<bool>>> DeActivateMember([FromQuery] Guid UserId)
        {
            var command = new DeActivateMemberCommand(UserId);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Member deactivated successfully", result));
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
