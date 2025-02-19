namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class VerifyEmailDTO
    {
        public required string Code { get; set; }
        public required Guid UserId { get; set; }
    }
}