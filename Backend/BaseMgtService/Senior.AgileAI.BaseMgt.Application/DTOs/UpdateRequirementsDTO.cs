using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class UpdateRequirementsDTO
    {
        public required Guid RequirementId { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public RequirementsStatus? Status { get; set; }
        public ReqPriority? Priority { get; set; }

    }
}