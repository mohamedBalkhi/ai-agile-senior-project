using System.Collections.Generic;

namespace Senior.AgileAI.BaseMgt.Domain.ValueObjects;

public class MeetingAIReport
{
    // At least one non-nullable property to identify existence
    public required string MainLanguage { get; set; }
    
    public string? Transcript { get; set; }
    public string? Summary { get; set; }
    public List<string>? KeyPoints { get; set; }

    // Constructor for new reports
    public static MeetingAIReport Create(
        string transcript,
        string summary,
        List<string> keyPoints,
        string mainLanguage)
    {
        return new MeetingAIReport
        {
            Transcript = transcript,
            Summary = summary,
            KeyPoints = keyPoints,
            MainLanguage = mainLanguage
        };
    }
}
