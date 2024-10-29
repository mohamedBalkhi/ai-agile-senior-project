using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class CreateProjectCommand : IRequest<Guid>
    {
        public CreateProjectDTO? Dto { get; set; }
        public Guid UserId { get; set; }

        public CreateProjectCommand(CreateProjectDTO dto, Guid userId)
        {
            Dto = dto;
            UserId = userId;
        }


    }
}