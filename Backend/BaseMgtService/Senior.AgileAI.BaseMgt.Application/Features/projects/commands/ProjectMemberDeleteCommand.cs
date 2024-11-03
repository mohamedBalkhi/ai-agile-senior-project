using MediatR;
namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class ProjectMemberDeleteCommand : IRequest<bool>
    {
        public  Guid ProjectId { get; set; }
        public  Guid MemberId { get; set; } //id for the OrgMember , not user.

        public ProjectMemberDeleteCommand(Guid projectId, Guid memberId)
        {
            this.ProjectId = projectId;
            this.MemberId = memberId;
        }
    }
}