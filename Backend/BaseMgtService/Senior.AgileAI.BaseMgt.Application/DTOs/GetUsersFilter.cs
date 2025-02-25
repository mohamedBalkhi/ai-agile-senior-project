namespace Senior.AgileAI.BaseMgt.Application.DTOs;

public class GetUsersFilter
{
    public string? SearchTerm { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsTrusted { get; set; }
    public bool? IsAdmin { get; set; }
    public bool? IsManager { get; set; }
    public Guid? OrganizationId { get; set; }
    public string? Country { get; set; }
}