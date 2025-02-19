using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;
using Senior.AgileAI.BaseMgt.Domain.Constants;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class TimeZoneService : ITimeZoneService
{
    public IEnumerable<TimeZoneDTO> GetAllTimeZones()
    {
        return TimeZoneInfo.GetSystemTimeZones()
            .Select(tz => new TimeZoneDTO
            {
                Id = tz.Id,
                DisplayName = TimeZoneConstants.GetDisplayName(tz.Id),
                UtcOffset = tz.BaseUtcOffset.ToString(),
                IsCommon = TimeZoneConstants.CommonTimeZones.Contains(tz.Id)
            })
            .OrderBy(tz => tz.UtcOffset);
    }

    public IEnumerable<TimeZoneDTO> GetCommonTimeZones()
    {
        return TimeZoneConstants.CommonTimeZones
            .Select(id => GetTimeZoneById(id))
            .Where(tz => tz != null)!;
    }

    public TimeZoneDTO? GetTimeZoneById(string id)
    {
        try
        {
            var tz = TimeZoneInfo.FindSystemTimeZoneById(id);
            return new TimeZoneDTO
            {
                Id = tz.Id,
                DisplayName = TimeZoneConstants.GetDisplayName(tz.Id),
                UtcOffset = tz.BaseUtcOffset.ToString(),
                IsCommon = TimeZoneConstants.CommonTimeZones.Contains(tz.Id)
            };
        }
        catch (TimeZoneNotFoundException)
        {
            return null;
        }
    }

    public bool ValidateTimeZone(string timeZoneId)
    {
        return TimeZoneConstants.IsValidTimeZone(timeZoneId);
    }
} 