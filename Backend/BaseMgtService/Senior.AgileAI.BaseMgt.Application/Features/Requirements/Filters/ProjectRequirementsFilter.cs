using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Filters
{
    public class ProjectRequirementsFilter
    {

        public ReqPriority? Priority { get; set; }
        public RequirementsStatus? Status { get; set; }
    }
}