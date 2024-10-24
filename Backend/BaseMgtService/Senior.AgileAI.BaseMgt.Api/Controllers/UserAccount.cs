using Microsoft.AspNetCore.Mvc;
using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;

namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserAccount : ControllerBase
    {
        private readonly IMediator _mediator;

        public UserAccount(IMediator mediator)
        {
            _mediator = mediator;
        }   

        [HttpPost("UpdateProfile")]
        public async Task<ActionResult<bool>> UpdateProfile(updateProfileDTO dto)
        {
            var command = new UpdateProfileCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        [HttpPost("DeactivateProfile")  ]
        public async Task<ActionResult<bool>> DeactivateProfile(Guid userId)
        {
            var command = new ProfileDeactivateCommand(userId);
            var result = await _mediator.Send(command);
            return Ok(result);
        }
        
    }
}