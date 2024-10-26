using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Features.Country.Queries;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;
using Senior.AgileAI.BaseMgt.Application.Common;



namespace Senior.AgileAI.BaseMgt.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CountryController : ControllerBase
    {
        private readonly IMediator _mediator;

        public CountryController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpGet("GetAllCountries")]
        public async Task<ActionResult<List<CountryDTO>>> GetAllCountries()
        {
            try
            {
                var command = new GetAllCountriesQuery();
                var result = await _mediator.Send(command);
                return Ok(new ApiResponse(200, "Countries fetched successfully", result));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}
