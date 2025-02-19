namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class CreateProjectDTO
    {
        public required string ProjectName { get; set; }
        public required string ProjectDescription { get; set; }
        public Guid ProjectManagerId { get; set; }

    }
}