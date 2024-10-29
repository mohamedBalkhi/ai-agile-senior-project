using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries
{
    public class GetOrganizationMembersQuery : IRequest<List<GetOrgMemberDTO>>
    {
        public Guid UserId { get; set; }
        public GetOrganizationMembersQuery(Guid userId)
        {
            UserId = userId;
        }
    }
}