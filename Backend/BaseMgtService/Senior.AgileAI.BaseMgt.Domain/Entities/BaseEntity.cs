using System.ComponentModel.DataAnnotations;

namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public abstract class BaseEntity
{
    [Key]
    public virtual Guid Id { get; set; }
    public DateTime CreatedDate { get; set; } 
    public DateTime UpdatedDate { get; set; }
}
