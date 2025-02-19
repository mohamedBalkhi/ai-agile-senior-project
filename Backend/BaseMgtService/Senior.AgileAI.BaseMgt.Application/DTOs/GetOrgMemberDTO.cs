namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class GetOrgMemberDTO
    {
        public required Guid MemberId { get; set; }
        public required string MemberName { get; set; }
        public required string MemberEmail { get; set; }
        public bool IsActive { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsManager { get; set; }
        public List<ProjectDTO>? Projects { get; set; } = new List<ProjectDTO>();

    }

    public class ProjectDTO
    {
        public required string ProjectName { get; set; }
        public required string ProjectDescription { get; set; }
    }

}