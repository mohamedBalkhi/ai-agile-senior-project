using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;
#nullable disable
namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queries
{
    public class GetProjectsByMemberQuery : IRequest<List<ProjectInfoDTO>>
    {
        public Guid MemberId { get; set; }

        public GetProjectsByMemberQuery(Guid memberId)
        {
            MemberId = memberId;
        }
    }
}