using Microsoft.AspNetCore.Mvc;
using MediatR;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Queries;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands;
using Senior.AgileAI.BaseMgt.Application.Common;



namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class Requirements : ControllerBase
    {
        private readonly IMediator _mediator;
        public Requirements(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpPost("AddReqManually")]
        public async Task<ActionResult<ApiResponse<bool>>> AddReqManually(AddReqManuallyDTO dto)
        {
            var command = new AddReqManuallyCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Requirements added successfully", result));
        }

        [HttpDelete("DeleteReqs")]
        public async Task<ActionResult<ApiResponse<List<bool>>>> DeleteReqs([FromBody] List<Guid> requirementIds)
        {
            var command = new DeleteReqsCommand(requirementIds);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<List<bool>>(200, "Requirements deleted successfully", result));
        }


        [HttpPut("UpdateReq")]
        public async Task<ActionResult<ApiResponse<bool>>> UpdateReq(UpdateRequirementsDTO dto)
        {
            var command = new UpdateRequirementsCommand(dto);
            var result = await _mediator.Send(command);
            return Ok(new ApiResponse<bool>(200, "Requirements updated successfully", result));
        }

        [HttpGet("GetProjectRequirements")]
        public async Task<ActionResult<ApiResponse<List<ProjectRequirementsDTO>>>> GetProjectRequirements([FromQuery] Guid projectId)
        {
            var query = new GetProjectRequirements(projectId);
            var result = await _mediator.Send(query);
            return Ok(new ApiResponse<List<ProjectRequirementsDTO>>(200, "Requirements fetched successfully", result));
        }

    }
}