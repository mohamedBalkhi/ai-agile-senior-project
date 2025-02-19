namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class SignUpDTO
    {
        public required string FullName { get; set; }
        public required string Email { get; set; }
        public required string Password { get; set; }
        public required DateOnly BirthDate { get; set; }
        public required Guid Country_IdCountry { get; set; }
        
        

    }
}