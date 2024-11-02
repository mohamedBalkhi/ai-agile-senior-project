using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Filters;


namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Queries
{
    public class GetProjectRequirements : IRequest<List<ProjectRequirementsDTO>>
    {
        public Guid ProjectId { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public ProjectRequirementsFilter? Filter { get; set; }
        public GetProjectRequirements(Guid projectId, int pageNumber, int pageSize, ProjectRequirementsFilter? filter)
        {
            ProjectId = projectId;
            PageNumber = pageNumber;
            PageSize = pageSize;
            Filter   = filter;
        }
    }
}