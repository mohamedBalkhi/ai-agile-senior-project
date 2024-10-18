namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public abstract class NamedEntity  : BaseEntity
{
    public required string Name {get; set;}
    public required string Description {get; set;}
}

