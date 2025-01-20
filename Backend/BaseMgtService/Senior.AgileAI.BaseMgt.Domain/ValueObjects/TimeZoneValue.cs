namespace Senior.AgileAI.BaseMgt.Domain.ValueObjects;

public class TimeZoneValue
{
    public string Id { get; private set; }
    public string DisplayName { get; private set; }
    public TimeSpan UtcOffset { get; private set; }
    
    private TimeZoneValue(string id, string displayName, TimeSpan utcOffset)
    {
        Id = id;
        DisplayName = displayName;
        UtcOffset = utcOffset;
    }
    
    public static TimeZoneValue FromTimeZoneInfo(TimeZoneInfo timeZoneInfo)
    {
        return new TimeZoneValue(
            timeZoneInfo.Id,
            timeZoneInfo.DisplayName,
            timeZoneInfo.BaseUtcOffset
        );
    }
    
    public static TimeZoneValue FromId(string id)
    {
        var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(id);
        return FromTimeZoneInfo(timeZoneInfo);
    }

    public TimeZoneInfo GetTimeZoneInfo()
    {
        return TimeZoneInfo.FindSystemTimeZoneById(Id);
    }
    
    public override string ToString()
    {
        var sign = UtcOffset.Hours >= 0 ? "+" : "-";
        return $"{DisplayName} (UTC{sign}{Math.Abs(UtcOffset.Hours):D2}:{UtcOffset.Minutes:D2})";
    }
} 