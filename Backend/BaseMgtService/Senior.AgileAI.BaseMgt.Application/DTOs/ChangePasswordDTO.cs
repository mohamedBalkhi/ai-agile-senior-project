namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class ChangePasswordDTO
    {
        public Guid UserId { get; set; }
        public required string OldPassword { get; set; }
        public required string NewPassword { get; set; }
    }
}