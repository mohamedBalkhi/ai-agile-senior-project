using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class ProjectDeactivateCommand : IRequest<bool>
    {
        public Guid ProjectId { get; set; }

        public ProjectDeactivateCommand(Guid projectId)
        {
            ProjectId = projectId;
        }
    }
}