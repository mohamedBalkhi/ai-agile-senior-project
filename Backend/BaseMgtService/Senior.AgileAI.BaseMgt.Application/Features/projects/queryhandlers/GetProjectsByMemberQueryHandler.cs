using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queryhandlers
{
    public class GetProjectsByMemberQueryHandler : IRequestHandler<GetProjectsByMemberQuery, List<ProjectInfoDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetProjectsByMemberQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<List<ProjectInfoDTO>> Handle(GetProjectsByMemberQuery request, CancellationToken cancellationToken)
        {
            var organizationMember = await _unitOfWork.OrganizationMembers.GetByUserId(request.MemberId, cancellationToken, true);
            if (organizationMember == null)
            {
                throw new NotFoundException("User not found");
            }
            var result = await _unitOfWork.ProjectPrivileges.GetProjectsByMember(organizationMember, cancellationToken);
            var projectInfoDTOs = new List<ProjectInfoDTO>();
            foreach (var projectPrivilege in result)
            {
                projectInfoDTOs.Add(new ProjectInfoDTO()
                {
                    ProjectId = projectPrivilege.Project.Id,
                    ProjectName = projectPrivilege.Project.Name,
                    ProjectDescription = projectPrivilege.Project.Description,
                    ProjectStatus = projectPrivilege.Project.Status,
                    ProjectManagerId = projectPrivilege.Project.ProjectManager_IdProjectManager,
                    ProjectManagerName = projectPrivilege.Project.ProjectManager.User.FUllName
                });
            }
            return projectInfoDTOs;
        }

    }
}