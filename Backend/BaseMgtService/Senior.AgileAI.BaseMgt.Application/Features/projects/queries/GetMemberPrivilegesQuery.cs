using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queries
{
    public class GetMemberPrivilegesQuery : IRequest<MemberPrivilegesDto>
    {
        public Guid ProjectId { get; set; }// from body
        public Guid MemberId { get; set; } //from token
        public GetMemberPrivilegesQuery(Guid projectId, Guid memberId)
        {
            ProjectId = projectId;
            MemberId = memberId;
        }


    }
}