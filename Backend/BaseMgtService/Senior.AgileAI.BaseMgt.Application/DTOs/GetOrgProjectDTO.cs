namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class GetOrgProjectDTO
    {
        public Guid Id { get; set; }
        public required string Name { get; set; }
        public required string Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? ProjectManager { get; set; }
    }
}