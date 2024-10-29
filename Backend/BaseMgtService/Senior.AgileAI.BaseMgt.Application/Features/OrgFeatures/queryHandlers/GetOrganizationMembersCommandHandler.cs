using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.QueryHandlers
{
    public class GetOrganizationMembersQueryHandler : IRequestHandler<GetOrganizationMembersQuery, List<GetOrgMemberDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetOrganizationMembersQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
#nullable disable

        public async Task<List<GetOrgMemberDTO>> Handle(GetOrganizationMembersQuery request, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
            var orgId = user.Organization.Id;
            var orgMembers = await _unitOfWork.OrganizationMembers.GetByOrgId(orgId, cancellationToken);
            var orgMembersDTO = orgMembers.Select(om => new GetOrgMemberDTO
            {
                MemberId = om.User_IdUser,//the user id not the id of the member
                MemberName = om.User.FUllName,
                MemberEmail = om.User.Email,
                IsActive = om.User.IsActive,
                Projects = om.ProjectPrivileges.Select(pp => new ProjectDTO
                {
                    ProjectName = pp.Project.Name,
                    ProjectDescription = pp.Project.Description
                }).ToList()
            }).ToList();
            return orgMembersDTO;
        }
    }
}