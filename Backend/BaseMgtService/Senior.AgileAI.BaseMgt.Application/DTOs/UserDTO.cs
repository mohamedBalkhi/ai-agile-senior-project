namespace Senior.AgileAI.BaseMgt.Application.DTOs;

public class UserDTO
{
   
        public required Guid UserId { get; set; }
        public required string FullName { get; set; }
        public required string Email { get; set; }
        public bool IsActive { get; set; }
        public bool IsTrusted { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsManager { get; set; }
        public Guid? OrganizationId { get; set; }
        public string OrganizationName { get; set; } = string.Empty;
        public required String Country;
}