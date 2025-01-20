namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class MeetingMember : BaseEntity
{
    public Guid Meeting_IdMeeting { get; set; }
    public Guid OrganizationMember_IdOrganizationMember { get; set; }
    public bool HasConfirmed { get; set; }
    
    // Navigation Properties
    public Meeting Meeting { get; set; } = null!;
    public OrganizationMember OrganizationMember { get; set; } = null!;
} 