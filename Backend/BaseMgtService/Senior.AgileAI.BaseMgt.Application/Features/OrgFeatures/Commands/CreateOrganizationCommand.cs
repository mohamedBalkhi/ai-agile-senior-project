using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class CreateOrganizationCommand : IRequest<Guid> //return the id of the organization
    {
        public CreateOrganizationDTO Dto { get; set; }
        public CreateOrganizationCommand(CreateOrganizationDTO dto)
        {
            Dto = dto;
        }

    }
}