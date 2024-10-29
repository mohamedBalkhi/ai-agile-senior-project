namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Project : NamedEntity
{

    public required bool Status { get; set; } // 0= active, 1= inactive.
    public Guid Organization_IdOrganization { get; set; }
    public Guid ProjectManager_IdProjectManager { get; set; }

    public Organization Organization { get; set; } = null!;
    public OrganizationMember ProjectManager { get; set; } = null!; 
    public ICollection<ProjectPrivilege>? ProjectPrivileges { get; set; } = new List<ProjectPrivilege>();
    public ICollection<ProjectRequirement>? ProjectRequirements { get; set; } = new List<ProjectRequirement>();
}
