namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Organization : NamedEntity
{
    
    public required string Status { get; set; }
    public required Guid OrganizationManager_IdOrganizationManager { get; set; }
    public required OrganizationMember OrganizationManager { get; set; } = null!;
    public required ICollection<OrganizationMember> OrganizationMembers { get; set; } = new List<OrganizationMember>();
    public required ICollection<Project> Projects { get; set; } = new List<Project>();
}
