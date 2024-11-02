using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands
{
    public class UpdateRequirementsCommand : IRequest<bool>
    {
        public UpdateRequirementsDTO DTO { get; set; }
        public UpdateRequirementsCommand(UpdateRequirementsDTO dto)
        {
            DTO = dto;
        }
    }
}