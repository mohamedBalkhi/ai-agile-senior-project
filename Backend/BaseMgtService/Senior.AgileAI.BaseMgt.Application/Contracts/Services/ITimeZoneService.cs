using Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public interface ITimeZoneService
{
    IEnumerable<TimeZoneDTO> GetAllTimeZones();
    IEnumerable<TimeZoneDTO> GetCommonTimeZones();
    TimeZoneDTO? GetTimeZoneById(string id);
    bool ValidateTimeZone(string timeZoneId);
} 