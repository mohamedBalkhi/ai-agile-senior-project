using Senior.AgileAI.BaseMgt.Domain.Enums;
namespace Senior.AgileAI.BaseMgt.Domain.Entities;


public class ProjectRequirement : BaseEntity
{

    public Guid Project_IdProject { get; set; }
    public required string Title { get; set; }
    public required ReqPriority Priority { get; set; }
    public required RequirementsStatus Status { get; set; }
    public required string Description { get; set; } //IT CAN HOLD THE USER STORY  ..   

    public Project Project { get; set; } = null!;

}



