namespace Senior.AgileAI.BaseMgt.Domain.Constants;

public static class TimeZoneConstants
{
    // Common timezones for our primary regions
    public const string UTC = "Etc/UTC";
    public const string UAE = "Asia/Dubai";
    public const string Egypt = "Africa/Cairo";
    public const string ArabiaStandard = "Asia/Riyadh";
    public const string EasternUS = "America/New_York";
    public const string Jordan = "Asia/Amman";
    public const string Kuwait = "Asia/Kuwait";
    public const string Qatar = "Asia/Qatar";
    public const string Bahrain = "Asia/Bahrain";
    public const string Oman = "Asia/Muscat";
    
    // Get all system timezones
    public static IReadOnlyCollection<TimeZoneInfo> GetAllTimeZones()
    {
        return TimeZoneInfo.GetSystemTimeZones();
    }
    
    // Common timezones for quick access
    public static readonly IReadOnlySet<string> CommonTimeZones = new HashSet<string>
    {
        UTC,
        UAE,
        Egypt,
        ArabiaStandard,
        EasternUS,
        Jordan,
        Kuwait,
        Qatar,
        Bahrain,
        Oman
    };
    
    // Validate timezone
    public static bool IsValidTimeZone(string timeZoneId)
    {
        try
        {
            TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
            return true;
        }
        catch (TimeZoneNotFoundException)
        {
            return false;
        }
    }
    
    // Helper method to get offset
    public static TimeSpan GetUtcOffset(string timeZoneId, DateTime dateTime)
    {
        var timeZone = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
        return timeZone.GetUtcOffset(dateTime);
    }
    
    // Get display name with offset
    public static string GetDisplayName(string timeZoneId)
    {
        var timeZone = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
        var offset = timeZone.BaseUtcOffset;
        var sign = offset.Hours >= 0 ? "+" : "-";
        return $"{timeZone.DisplayName} (UTC{sign}{Math.Abs(offset.Hours):D2}:{offset.Minutes:D2})";
    }
} 