using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queries
{
    public class GetProjectInfoQuery : IRequest<ProjectInfoDTO>
    {
        public Guid ProjectId { get; set; }
        public Guid UserId { get; set; }

        public GetProjectInfoQuery(Guid projectId, Guid userId)
        {
            ProjectId = projectId;
            UserId = userId;
        }
    }
}