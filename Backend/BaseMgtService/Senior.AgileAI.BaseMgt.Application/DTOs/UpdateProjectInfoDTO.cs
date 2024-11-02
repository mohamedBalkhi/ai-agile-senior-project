using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class UpdateProjectInfoDTO
    {
        public required Guid ProjectId { get; set; }
        public string? ProjectName { get; set; }
        public string? ProjectDescription { get; set; }
        public bool? ProjectStatus { get; set; }
        public Guid? ManagerId { get; set; }

    }
}