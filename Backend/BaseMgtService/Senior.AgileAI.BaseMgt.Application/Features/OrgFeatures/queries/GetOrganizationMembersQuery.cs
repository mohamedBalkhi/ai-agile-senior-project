using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries
{
    public class GetOrganizationMembersQuery : IRequest<List<GetOrgMemberDTO>>
    {
        public Guid UserId { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public bool? IsActiveFilter { get; set; }

        public GetOrganizationMembersQuery(Guid userId, int pageNumber = 1, int pageSize = 10, bool? isActiveFilter = null)
        {
            UserId = userId;
            PageNumber = pageNumber;
            PageSize = pageSize;
            IsActiveFilter = isActiveFilter;
        }
    }
}