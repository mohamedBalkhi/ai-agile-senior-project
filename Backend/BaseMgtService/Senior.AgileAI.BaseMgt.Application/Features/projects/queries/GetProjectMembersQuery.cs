using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queries
{
    public class GetProjectMembersQuery : IRequest<List<ProjectMemberDTO>>
    {
        public Guid ProjectId { get; set; } // from body
        public Guid UserId { get; set; }// from token

        public GetProjectMembersQuery(Guid projectId, Guid userId)
        {
            ProjectId = projectId;
            UserId = userId;
        }
    }
}