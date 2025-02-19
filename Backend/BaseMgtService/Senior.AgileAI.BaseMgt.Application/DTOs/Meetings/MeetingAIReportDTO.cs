using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;

public class MeetingAIReportDTO
{
    public string? Transcript { get; set; }
    public string? Summary { get; set; }
    public List<string>? KeyPoints { get; set; }
    public string? MainLanguage { get; set; }
    public AIProcessingStatus ProcessingStatus { get; set; }
    public DateTime? ProcessedAt { get; set; }
}
