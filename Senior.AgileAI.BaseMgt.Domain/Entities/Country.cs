namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class Country : BaseEntity 
{
    public required string Name { get; set; }
    public required string Code { get; set; }
    public required bool IsActive { get; set; }

    public required ICollection<User> Users {get;set;} = new List<User>();

    public Country()
    {
        IsActive = true;
    }
}
