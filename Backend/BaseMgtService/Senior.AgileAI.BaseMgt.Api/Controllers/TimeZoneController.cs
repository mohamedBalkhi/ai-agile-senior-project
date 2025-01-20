using Microsoft.AspNetCore.Mvc;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;

namespace Senior.AgileAI.BaseMgt.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TimeZoneController : ControllerBase
{
    private readonly ITimeZoneService _timeZoneService;
    private readonly IAudioStorageService _audioStorageService;
        
    public TimeZoneController(ITimeZoneService timeZoneService, IAudioStorageService audioStorageService)
    {
        _timeZoneService = timeZoneService;
        _audioStorageService = audioStorageService;
    }

    [HttpGet]
    public ActionResult<IEnumerable<TimeZoneDTO>> GetAll()
    {
        return Ok(_timeZoneService.GetAllTimeZones());
    }

    [HttpGet("common")]
    public ActionResult<IEnumerable<TimeZoneDTO>> GetCommon()
    {
        return Ok(_timeZoneService.GetCommonTimeZones());
    }

    [HttpGet("{id}")]
    public ActionResult<TimeZoneDTO> GetById(string id)
    {
        var timeZone = _timeZoneService.GetTimeZoneById(id);
        if (timeZone == null)
            return NotFound();
            
        return Ok(timeZone);
    }

    [HttpPost("TestUploadingAudio")]
    public async Task<ActionResult<ApiResponse<string>>> UploadAudio(IFormFile audioFile) {

        var audioUrl = await _audioStorageService.UploadAudioAsync(Guid.NewGuid(), audioFile, CancellationToken.None);
        var preSignedUrl = await _audioStorageService.GetPreSignedUrlAsync(audioUrl, TimeSpan.FromHours(12));

        return Ok(new ApiResponse<string>(200, "Success", "Audio uploaded successfully", preSignedUrl));
    }
} 