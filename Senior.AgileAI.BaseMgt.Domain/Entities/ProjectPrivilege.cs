namespace Senior.AgileAI.BaseMgt.Domain.Entities;
public class ProjectPrivilege : BaseEntity
{
    
    public required Guid Project_IdProject { get; set; }
    public required Guid OrganizationMember_IdOrganizationMember { get; set; }
    public PrivilegeLevel Documents { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Meetings { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Settings { get; set; } = PrivilegeLevel.None;
    public PrivilegeLevel Users { get; set; } = PrivilegeLevel.Read;
    // public PrivilegeLevel Tasks {get; set;} = PrivilegeLevel.Read;
    public required Project Project { get; set; } = null!;
    public required OrganizationMember OrganizationMember { get; set; } = null!;
}

public enum PrivilegeLevel
{
    None = 0,
    Read = 1,
    Write = 2
}
