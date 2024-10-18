namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Project : NamedEntity
{
    
    public required string Status { get; set; }
    public required Guid Organization_IdOrganization { get; set; }
    public required Guid ProjectManager_IdProjectManager { get; set; }

    public required Organization Organization { get; set; } = null!;
    public required OrganizationMember ProjectManager { get; set; } = null!;
    public required ICollection<ProjectPrivilege> ProjectPrivileges { get; set; } = new List<ProjectPrivilege>();
    public required ICollection<ProjectRequirement> ProjectRequirements {get;set;} = new List<ProjectRequirement>();
}
