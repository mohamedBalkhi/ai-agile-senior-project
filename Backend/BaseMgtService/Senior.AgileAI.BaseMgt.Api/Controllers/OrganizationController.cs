using MediatR;
using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;

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
            var command = new CreateOrganizationCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        // [HttpGet("GetOrganizationbyMemberId/{id}")]
        // public async Task<ActionResult<OrganizationDTO>> GetOrganizationbyMemberId(Guid id)


    }
}