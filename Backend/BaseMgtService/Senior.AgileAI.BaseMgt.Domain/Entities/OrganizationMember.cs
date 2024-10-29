namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class OrganizationMember : BaseEntity
{
    
    public  Guid Organization_IdOrganization { get; set; }
    public  Guid User_IdUser { get; set; }
    public required bool IsManager { get; set; } // Manager of the organization
    public required bool HasAdministrativePrivilege { get; set; } // Has administrative privileges for the organization
    public  Organization Organization { get; set; } = null!;
    public  User User { get; set; } = null!;
    public  ICollection<ProjectPrivilege> ProjectPrivileges { get; set; } = new List<ProjectPrivilege>();
}
