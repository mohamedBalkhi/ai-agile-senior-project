namespace Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;

public class ProjectPrivilege : BaseEntity
{
    public Guid Project_IdProject { get; set; }
    public Guid OrganizationMember_IdOrganizationMember { get; set; }
    public PrivilegeLevel Settings { get; set; } = PrivilegeLevel.None;
    public PrivilegeLevel Meetings { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Members { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Requirements { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Tasks { get; set; } = PrivilegeLevel.Read;
    public Project Project { get; set; } = null!;
    public OrganizationMember OrganizationMember { get; set; } = null!;
}
