using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class UpdateProjectPrivilagiesCommand : IRequest<bool>
    {
        public UpdateProjectPrivilegesDTO Dto { get; set; }
        public UpdateProjectPrivilagiesCommand(UpdateProjectPrivilegesDTO dto)
        {
            Dto = dto;
        }

    }
}