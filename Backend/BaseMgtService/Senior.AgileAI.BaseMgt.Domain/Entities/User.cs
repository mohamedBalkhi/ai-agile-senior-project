namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class User : BaseEntity
{

    public required string Name { get; set; }
    public required string Email { get; set; }
    public required string Password { get; set; }

    public required DateOnly BirthDate {get;set;}
    public  Guid Country_IdCountry {get;set;}
    


    public required string Status { get; set; }
    public required bool isAdmin {get; set;}
    public  Country Country {get;set;} = null!;
    public OrganizationMember? OrganizationMember { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

}



