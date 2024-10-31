using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class AddOrgMembersCommand : IRequest<AddOrgMembersResponseDTO>
    {
        public Guid UserId { get; set; }
        public AddOrgMembersDTO Dto { get; set; }
        public AddOrgMembersCommand(AddOrgMembersDTO Dto, Guid userId)
        {
            this.Dto = Dto;
            UserId = userId;
        }
    }
}