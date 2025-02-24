using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class AdminDashboardDto
    {
        public int UsersCount { get; set; }
        public int OrgCount { get; set; }
        public required List<OrgCreationDate> ChartOne { get; set; }
        public required List<ProjectsPerOrg> ChartTwo { get; set; }
        public required List<MembersPerOrg> ChartThree { get; set; }

    }

    public class OrgCreationDate
    {
        public Guid OrgId { get; set; }
        public required string OrgName { get; set; }
        public DateTime CreatedDate { get; set; }
    }




    public class ProjectsPerOrg
    {
        public Guid OrgId { get; set; }
        public required String OrgName { get; set; }
        public int ProjectsNo { get; set; }
    }


    public class MembersPerOrg
    {
        public Guid OrgId { get; set; }
        public required String OrgName { get; set; }
        public int MembersNo { get; set; }
    }

}