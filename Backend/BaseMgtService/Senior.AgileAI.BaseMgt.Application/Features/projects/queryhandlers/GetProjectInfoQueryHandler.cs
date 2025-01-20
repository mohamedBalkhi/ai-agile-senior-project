using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queryhandlers
{
    public class GetProjectInfoQueryHandler : IRequestHandler<GetProjectInfoQuery, ProjectInfoDTO>
    {
        // private readonly PrivilegeLevel _privilegeLevel = PrivilegeLevel.Write;
        // private readonly ProjectAspect _projectAspect = ProjectAspect.Settings;

        private readonly IUnitOfWork _unitOfWork;

        // private readonly IProjectAuthorizationHelper _projectAuthorizationHelper;

        public GetProjectInfoQueryHandler(IUnitOfWork unitOfWork, IProjectAuthorizationHelper projectAuthorizationHelper)
        {
            _unitOfWork = unitOfWork;
            // _projectAuthorizationHelper = projectAuthorizationHelper;
        }

        public async Task<ProjectInfoDTO> Handle(GetProjectInfoQuery request, CancellationToken cancellationToken)
        {
            // var hasPrivilege = await _projectAuthorizationHelper.HasProjectPrivilege(request.UserId, request.ProjectId, _projectAspect, _privilegeLevel, cancellationToken);
            // if (!hasPrivilege)
            // {
                // throw new UnauthorizedAccessException("User does not have the required privilege to access this project");
            // }
            var project = await _unitOfWork.Projects.GetByIdAsync(request.ProjectId, cancellationToken, includeProjectManager: true);
            var projectInfoDTO = new ProjectInfoDTO
            {
                ProjectId = project.Id,
                ProjectName = project.Name,
                ProjectDescription = project.Description,
                ProjectStatus = project.Status,
                ProjectManagerId = project.ProjectManager.User_IdUser,
                ProjectManagerName = project.ProjectManager.User.FUllName,
                ProjectCreatedAt = project.CreatedDate
            };
            return projectInfoDTO;
        }
    }
}