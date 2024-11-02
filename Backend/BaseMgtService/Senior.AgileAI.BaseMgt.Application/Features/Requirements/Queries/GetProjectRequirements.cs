using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;


namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Queries
{
    public class GetProjectRequirements : IRequest<List<ProjectRequirementsDTO>>
    {
        public Guid ProjectId { get; set; }
        public GetProjectRequirements(Guid projectId)
        {
            ProjectId = projectId;
        }
    }
}