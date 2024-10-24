using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class SignUpDTO
    {
        public required string Name { get; set; }
        public required string Email { get; set; }
        public required string Password { get; set; }
        public required DateOnly BirthDate { get; set; }
        public required Guid Country_IdCountry { get; set; }
        
        

    }
}