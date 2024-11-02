using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
#nullable disable
    public class ProjectRequirementsDTO
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public ReqPriority Priority { get; set; }
        public RequirementsStatus Status { get; set; }
    }
}