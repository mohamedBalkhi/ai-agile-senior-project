using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Common;
using Microsoft.AspNetCore.Authorization;

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

        





        // [HttpGet("GetOrganizationbyMemberId/{id}")]
        // public async Task<ActionResult<OrganizationDTO>> GetOrganizationbyMemberId(Guid id)


    }
}