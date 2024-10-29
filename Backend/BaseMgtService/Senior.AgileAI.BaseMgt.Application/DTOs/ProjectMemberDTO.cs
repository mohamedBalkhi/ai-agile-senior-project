using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class ProjectMemberDTO
    {
        public Guid Id { get; set; }
        public required string Name { get; set; }
        public required string Email { get; set; }
        public required string Meetings { get; set; }
        public required string Members { get; set; }
        public required string Requirements { get; set; }
        public required string Tasks { get; set; }
        public required string Settings { get; set; }
    }
}