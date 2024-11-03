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

        public GetOrganizationMembersQuery(Guid userId, int pageNumber, int pageSize, bool? isActiveFilter)
        {
            UserId = userId;
            PageNumber = pageNumber;
            PageSize = pageSize;
            IsActiveFilter = isActiveFilter;
        }
    }
}