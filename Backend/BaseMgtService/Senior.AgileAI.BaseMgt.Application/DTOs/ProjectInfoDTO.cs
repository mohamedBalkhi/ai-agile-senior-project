using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class ProjectInfoDTO
    {
        public required string ProjectName { get; set; }
        public required string ProjectDescription { get; set; }
        public required bool ProjectStatus { get; set; }
        public required Guid ProjectManagerId { get; set; }
        public required string ProjectManagerName { get; set; }
    }
}