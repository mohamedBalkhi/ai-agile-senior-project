using Senior.AgileAI.BaseMgt.Domain.Enums;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class AddReqManuallyDTO
    {
        public Guid ProjectId { get; set; }
        public List<ReqDTO> Requirements { get; set; }
    }

    public class ReqDTO
    {
        public required string Title { get; set; }
        public required ReqPriority Priority { get; set; }
        public required RequirementsStatus Status { get; set; }
        public required string Description { get; set; }

    }
}