namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class ProjectRequirement : BaseEntity {
    
    public required Guid Project_IdProject {get;set;}
    public required string Title {get;set;}
    public required string Priority {get;set;}
    public required string Status {get;set;}


    public required Project Project {get;set;} = null!;
    
}
