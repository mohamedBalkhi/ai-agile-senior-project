namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class UpdateProjectInfoDTO
    {
        public string? ProjectName { get; set; }
        public string? ProjectDescription { get; set; }
        public bool? ProjectStatus { get; set; }
        public Guid? ManagerId { get; set; }

    }
}