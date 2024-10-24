using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class CreateOrganizationDTO
    {
        public Guid UserId { get; set; }
        public required string Name { get; set; }
        public required string Description { get; set; }
        public required string Logo { get; set; }
    }
}