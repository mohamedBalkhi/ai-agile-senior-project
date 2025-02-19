namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class ProfileDTO
    {
        public required string FullName { get; set; }
        public required string Email { get; set; }
        public required string CountryName { get; set; }
        //TODO: public string ProfilePicture { get; set; }
        public required DateOnly BirthDate { get; set; }
        public string? OrganizationName { get; set; }

    }
}