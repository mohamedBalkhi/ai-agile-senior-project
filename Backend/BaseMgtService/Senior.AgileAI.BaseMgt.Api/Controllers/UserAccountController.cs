using Microsoft.AspNetCore.Mvc;
using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Queries;
using Senior.AgileAI.BaseMgt.Application.Common;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;

namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserAccountController : ControllerBase
    {
        private readonly IMediator _mediator;
        private readonly ITokenResolver _tokenResolver;

        public UserAccountController(IMediator mediator, ITokenResolver tokenResolver)
        {
            _mediator = mediator;
            _tokenResolver = tokenResolver;
        }

        [HttpPut("UpdateProfile")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<Guid>>> UpdateProfile([FromBody] updateProfileDTO dto)
        {
            try
            {
                var userId = _tokenResolver.ExtractUserId();
                var command = new UpdateProfileCommand(dto, userId ?? Guid.Empty);
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<Guid>(200, "Profile updated successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new ApiResponse<Guid>(400, "Validation failed", default, null, 
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<Guid>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<Guid>(500, "An error occurred", default, ex.Message));
            }
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
                return BadRequest(new ApiResponse<bool>(400, "Validation failed", default, null,
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<bool>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<bool>(500, "An error occurred", default, ex.Message));
            }
        }

        [HttpGet("GetProfileInformation")]
        public async Task<ActionResult<ApiResponse<ProfileDTO>>> GetProfileInformation([FromQuery] Guid userId)
        {
            try
            {
                var query = new GetProfileInfromationQuery(userId);
                var result = await _mediator.Send(query);
                return Ok(new ApiResponse<ProfileDTO>(200, "Profile information retrieved successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new ApiResponse<ProfileDTO>(400, "Validation failed", default, null,
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<ProfileDTO>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<ProfileDTO>(500, "An error occurred", default, ex.Message));
            }
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
                return BadRequest(new ApiResponse<bool>(400, "Validation failed", default, null,
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<bool>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<bool>(500, "An error occurred", default, ex.Message));
            }
        }

        [HttpPost("ForgetPassword")]
        public async Task<ActionResult<ApiResponse<bool>>> ForgetPassword(ForgetPasswordCommand command)
        {
            try
            {
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<bool>(200, "Password changed successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new ApiResponse<bool>(400, "Validation failed", default, null,
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<bool>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<bool>(500, "An error occurred", default, ex.Message));
            }
        }

        [HttpPost("RequestPasswordReset")]
        public async Task<ActionResult<ApiResponse<Guid>>> RequestPasswordReset(RequestPasswordResetCommand command)
        {
            try
            {
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse<Guid>(200, "Password reset requested successfully", result));
            }
            catch (ValidationException ex)
            {
                return BadRequest(new ApiResponse<Guid>(400, "Validation failed", default, null,
                    ex.Errors.ToDictionary(x => x.PropertyName, x => x.ErrorMessage)));
            }
            catch (NotFoundException ex)
            {
                return NotFound(new ApiResponse<Guid>(404, ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<Guid>(500, "An error occurred", default, ex.Message));
            }
        }
    }
}
