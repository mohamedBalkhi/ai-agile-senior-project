using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class updateProfileDTO
    {
        public string? FullName { get; set; } //the frontend can only send the updated fields.
        public DateOnly? BirthDate { get; set; }
        public Guid? CountryId { get; set; }
        // TODO: add the profile picture
    }
}