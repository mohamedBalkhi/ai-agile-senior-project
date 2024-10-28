namespace Senior.AgileAI.BaseMgt.Domain.Entities;
public class ProjectPrivilege : BaseEntity
{
    public Guid Project_IdProject { get; set; }
    public Guid OrganizationMember_IdOrganizationMember { get; set; }
    // public PrivilegeLevel Documents { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Meetings { get; set; } = PrivilegeLevel.Read;
    public PrivilegeLevel Settings { get; set; } = PrivilegeLevel.None;
    public PrivilegeLevel Users { get; set; } = PrivilegeLevel.Read;
    // public PrivilegeLevel Tasks {get; set;} = PrivilegeLevel.Read;
    public  Project Project { get; set; } = null!;
    public  OrganizationMember OrganizationMember { get; set; } = null!;
}

public enum PrivilegeLevel
{
    None = 0,
    Read = 1,
    Write = 2
}

// PrivillegeLevel.Write 

public static class ProjectPrivilegeAspect {
    public const string Meetings = "Meetings";
    public const string Settings = "Settings";
    public const string Users = "Users";
}
// ProjectPrivilegeAspect.Meetings 


// IsPrvileged = HasNeededPrivilege(Member, Project, ProjectPrivilegeAspect.Meetings, PrivilegeLevel.Write)
