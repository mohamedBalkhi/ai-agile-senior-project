using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class UpdateProjectInfoCommand : IRequest<bool>
    {
        public required Guid ProjectId { get; set; }
        public required UpdateProjectInfoDTO UpdateProjectInfo { get; set; }

        public UpdateProjectInfoCommand()
        {
        }

        public UpdateProjectInfoCommand(UpdateProjectInfoDTO updateProjectInfo, Guid projectId)
        {
            ProjectId = projectId;
            UpdateProjectInfo = updateProjectInfo;
        }
    }
}