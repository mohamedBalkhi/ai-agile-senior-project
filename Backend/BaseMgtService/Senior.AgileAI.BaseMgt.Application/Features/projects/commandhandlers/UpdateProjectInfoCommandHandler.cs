using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class UpdateProjectInfoCommandHandler : IRequestHandler<UpdateProjectInfoCommand, bool>
    {

        private readonly IUnitOfWork _unitOfWork;

        public UpdateProjectInfoCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(UpdateProjectInfoCommand request, CancellationToken cancellationToken)
        {
            var project = await _unitOfWork.Projects.GetByIdAsync(request.ProjectId);
            if (project == null)
            {
                throw new Exception("Project not found");
            }

            project.Name = request.UpdateProjectInfo.ProjectName ?? project.Name;
            project.Description = request.UpdateProjectInfo.ProjectDescription ?? project.Description;
            project.Status = request.UpdateProjectInfo.ProjectStatus ?? project.Status;
            if (request.UpdateProjectInfo.ManagerId != null)
            {
                project.ProjectManager_IdProjectManager = request.UpdateProjectInfo.ManagerId.Value;
                var projectPrivileges = await _unitOfWork.ProjectPrivileges.GetProjectPrivilegeByMember(request.UpdateProjectInfo.ManagerId.Value, request.ProjectId, cancellationToken);
                Console.WriteLine(projectPrivileges);

                if (projectPrivileges == null)  //? base on the bussines flow, this case must never happen.
                {
                    projectPrivileges = new ProjectPrivilege
                    {
                        Project_IdProject = request.ProjectId,
                        OrganizationMember_IdOrganizationMember = request.UpdateProjectInfo.ManagerId.Value,
                        Meetings = PrivilegeLevel.Write,
                        Requirements = PrivilegeLevel.Write,
                        Tasks = PrivilegeLevel.Write,
                        Settings = PrivilegeLevel.Write,
                        Members = PrivilegeLevel.Write
                    };
                    await _unitOfWork.ProjectPrivileges.AddAsync(projectPrivileges, cancellationToken);
                }
                else
                {
                    projectPrivileges.Meetings = PrivilegeLevel.Write;
                    projectPrivileges.Requirements = PrivilegeLevel.Write;
                    projectPrivileges.Tasks = PrivilegeLevel.Write;
                    projectPrivileges.Settings = PrivilegeLevel.Write;
                    projectPrivileges.Members = PrivilegeLevel.Write;
                }

            }
            else
            {
                project.ProjectManager_IdProjectManager = project.ProjectManager_IdProjectManager;
            }

            _unitOfWork.Projects.Update(project);
            return await _unitOfWork.CompleteAsync() > 0;
        }

    }
}