using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class CreateProjectDTO
    {
        public required string ProjectName { get; set; }
        public required string ProjectDescription { get; set; }
        public Guid ProjectManagerId { get; set; }

    }
}