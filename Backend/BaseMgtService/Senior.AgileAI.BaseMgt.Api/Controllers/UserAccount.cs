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
        public async Task<ActionResult<ApiResponse<Guid>>> UpdateProfile(updateProfileDTO dto)
        {
            // try
            // {
            var command = new UpdateProfileCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<Guid>(200, "Profile updated successfully", result));
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
        public async Task<ActionResult<ApiResponse<bool>>> DeactivateProfile([FromQuery] Guid userId)
        {
            try
            {
                var command = new ProfileDeactivateCommand(userId);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<bool>(200, "Profile deactivated successfully", result));
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
        public async Task<ActionResult<ApiResponse<ProfileDTO>>> GetProfileInformation([FromQuery] Guid userId)
        {
            // try
            // {
            var query = new GetProfileInfromationQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse<ProfileDTO>(200, "Profile information retrieved successfully", result));
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

        [HttpPost("ChangePassword")]
        public async Task<ActionResult<ApiResponse<bool>>> ChangePassword(ChangePasswordDTO dto)
        {
            try
            {
                var command = new ChangePasswordCommand(dto);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<bool>(200, "Password changed successfully", result));
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

        [HttpPost("ForgetPassword")] //TODO: test
        public async Task<ActionResult<ApiResponse<bool>>> ForgetPassword(ForgetPasswordCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Password changed successfully", result));
        }

        [HttpPost("RequestPasswordReset")]
        public async Task<ActionResult<ApiResponse<Guid>>> RequestPasswordReset(RequestPasswordResetCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<Guid>(200, "Password reset requested successfully", result));
        }


    }
}
