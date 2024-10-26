using Microsoft.AspNetCore.Mvc;
using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Queries;
using Senior.AgileAI.BaseMgt.Application.Common;
using FluentValidation;


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
            // try
            // {
            var command = new UpdateProfileCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse(200, "Profile updated successfully", result));
            // }
            // catch (ValidationException ex)
            // {
            //     return BadRequest(new { message = ex.Message });
            // }
            // catch (Exception ex)
            // {
            //     return StatusCode(500, new { message = ex.Message });
            // }
        }

        [HttpPost("DeactivateAccount")]
        public async Task<ActionResult<bool>> DeactivateProfile(Guid userId)
        {
            try
            {
                var command = new ProfileDeactivateCommand(userId);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse(200, "Profile deactivated successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }


        [HttpGet("GetProfileInformation")]
        public async Task<ActionResult<ProfileDTO>> GetProfileInformation(Guid userId)
        {
            // try
            // {
            var query = new GetProfileInfromationQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse(200, "Profile information retrieved successfully", result));
            // }
            // catch (ValidationException ex)
            // {
            //     return BadRequest(new
            //     {
            //         Message = "Validation failed",
            //         Error = ex.Errors
            // //     });
            // }
            // catch (Exception ex)
            // {
            // return StatusCode(500, new
            // {
            // Message = "An error occurred while processing your request",
            //     Error = ex.Message
            // });

        }


    }
}
