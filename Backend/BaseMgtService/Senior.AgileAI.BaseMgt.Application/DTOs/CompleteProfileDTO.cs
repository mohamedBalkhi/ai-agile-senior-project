namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class CompleteProfileDTO
    {
        public required string FullName { get; set; }
        public required DateOnly BirthDate { get; set; }
        public required Guid CountryId { get; set; }
        public required string Password { get; set; }

    }
}