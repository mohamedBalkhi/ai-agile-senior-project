namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Organization : NamedEntity
{

    public required string Status { get; set; }
    public Guid? OrganizationManager_IdOrganizationManager { get; set; }
    public User? OrganizationManager { get; set; }
    public ICollection<OrganizationMember>? OrganizationMembers { get; set; } = new List<OrganizationMember>();
    public ICollection<Project>? Projects { get; set; } = new List<Project>();
    public bool IsActive { get; set; } = true;

    public string? Logo { get; set; } //logo is a url to the image.

}


