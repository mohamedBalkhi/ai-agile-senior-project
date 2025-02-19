namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class ProjectInfoDTO
    {
        public required Guid ProjectId { get; set; }
        public required string ProjectName { get; set; }
        public required string ProjectDescription { get; set; }
        public required bool ProjectStatus { get; set; }
        public required Guid ProjectManagerId { get; set; }
        public required string ProjectManagerName { get; set; }
        public DateTimeOffset ProjectCreatedAt { get; set; }
    }
}