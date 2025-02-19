using Microsoft.AspNetCore.Http;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class CreateOrganizationDTO
    {
        public Guid UserId { get; set; } //it will used as the manger id
        public required string Name { get; set; }
        public required string Description { get; set; }
        public IFormFile? LogoFile { get; set; }
    }
}