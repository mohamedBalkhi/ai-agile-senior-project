namespace Senior.AgileAI.BaseMgt.Application.DTOs.TimeZone;

public record TimeZoneDTO
{
    public required string Id { get; init; }
    public required string DisplayName { get; init; }
    public required string UtcOffset { get; init; }
    public required bool IsCommon { get; init; }
} 