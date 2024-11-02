using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class UpdateProjectInfoCommand : IRequest<bool>
    {
        public UpdateProjectInfoDTO UpdateProjectInfo { get; set; }

        public UpdateProjectInfoCommand(UpdateProjectInfoDTO updateProjectInfo)
        {
            UpdateProjectInfo = updateProjectInfo;
        }

    }
}