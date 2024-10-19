namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class OrganizationMember : BaseEntity
{
    
    public required Guid Organization_IdOrganization { get; set; }
    public required Guid User_IdUser { get; set; }
    public required bool IsManager { get; set; } // Manager of the organization
    public required bool HasAdministrativePrivilege { get; set; } // Has administrative privileges for the organization

    public required Organization Organization { get; set; } = null!;
    public required User User { get; set; }
    public required ICollection<ProjectPrivilege> ProjectPrivileges { get; set; } = new List<ProjectPrivilege>();
}
