using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class VerifyEmailDTO
    {
        public required string Code { get; set; }
        public required Guid UserId { get; set; }
    }
}