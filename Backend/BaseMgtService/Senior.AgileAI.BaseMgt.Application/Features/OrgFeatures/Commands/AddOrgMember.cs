using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class AddOrgMember : IRequest<bool>
    {
        public Guid UserId { get; set; }
        public OrgMemberDTO Dto { get; set; }
        public AddOrgMember(OrgMemberDTO Dto, Guid userId)
        {
            this.Dto = Dto;
            UserId = userId;
        }
    }
}