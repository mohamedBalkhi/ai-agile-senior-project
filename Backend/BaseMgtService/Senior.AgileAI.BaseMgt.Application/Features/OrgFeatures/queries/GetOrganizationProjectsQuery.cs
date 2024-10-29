using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries
{
    public class GetOrganizationProjectsQuery : IRequest<List<GetOrgProjectDTO>>
    {
        public Guid UserId { get; set; }    
        public GetOrganizationProjectsQuery(Guid userId)
        {
            UserId = userId;
        }
    }
}