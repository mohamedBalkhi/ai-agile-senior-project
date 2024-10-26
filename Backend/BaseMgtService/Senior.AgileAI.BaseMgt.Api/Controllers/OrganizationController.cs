using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using FluentValidation;

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
        public async Task<ActionResult<bool>> CreateOrganization(CreateOrganizationDTO dto)
        {
            try{
            var command = new CreateOrganizationCommand(dto);
            var result = await _mediator.Send(command);
                return Ok(result);
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

        

        // [HttpGet("GetOrganizationbyMemberId/{id}")]
        // public async Task<ActionResult<OrganizationDTO>> GetOrganizationbyMemberId(Guid id)


    }
}