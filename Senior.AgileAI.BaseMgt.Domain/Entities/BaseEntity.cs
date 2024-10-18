using System.ComponentModel.DataAnnotations;

namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public abstract class BaseEntity
{
    [Key]
    public virtual Guid Id { get; set; }
    public required DateTime CreatedDate { get; set; }
    public required DateTime UpdatedDate { get; set; }
}
