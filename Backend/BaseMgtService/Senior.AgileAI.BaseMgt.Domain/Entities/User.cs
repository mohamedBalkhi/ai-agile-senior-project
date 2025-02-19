namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class User : BaseEntity
{

    public required string FUllName { get; set; }
    public required string Email { get; set; }
    public required string Password { get; set; }
    public required DateOnly BirthDate { get; set; }
    public Guid Country_IdCountry { get; set; }
    public string? Code { get; set; }

    // public required string ProfilePicture { get; set; } 
    // TODO: Add Profile Picture Mohamed

    public required bool IsActive { get; set; } = false;

    public required bool Deactivated {get; set;} = false;
    public required bool IsTrusted { get; set; } = false;
    public required bool IsAdmin { get; set; } = false;
    public Country Country { get; set; } = null!;
    public Organization? Organization { get; set; }
    public OrganizationMember? OrganizationMember { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

    public virtual ICollection<NotificationToken> NotificationTokens { get; set; } = new List<NotificationToken>();

}



