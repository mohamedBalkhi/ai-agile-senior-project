using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

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
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken, includeOrganization: true, includeOrganizationMember: true)
                ?? throw new InvalidOperationException($"User with ID {request.UserId} not found");
            Console.WriteLine("user.Organization: " + user.Organization);
            var orgId = user.Organization?.Id ?? user.OrganizationMember.Organization_IdOrganization;
            var orgMembers = await _unitOfWork.OrganizationMembers.GetByOrgIdPaginated(orgId, request.PageNumber, request.PageSize, cancellationToken);

            if (request.IsActiveFilter != null)
                orgMembers = orgMembers.Where(om => om.User.IsActive == request.IsActiveFilter).ToList();

            var orgMembersDTO = orgMembers.Select(om => new GetOrgMemberDTO
            {
                MemberId = om.User_IdUser,// the user id not the id of the member
                MemberName = om.User.FUllName,
                MemberEmail = om.User.Email,
                IsActive = om.User.IsActive,
                IsAdmin = om.HasAdministrativePrivilege || om.IsManager,
                IsManager = om.IsManager,
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