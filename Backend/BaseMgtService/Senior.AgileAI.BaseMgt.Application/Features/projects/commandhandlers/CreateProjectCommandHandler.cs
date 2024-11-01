using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class CreateProjectCommandHandler : IRequestHandler<CreateProjectCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;

        public CreateProjectCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
        public async Task<Guid> Handle(CreateProjectCommand request, CancellationToken cancellationToken)
        {
            var transaction = await _unitOfWork.BeginTransactionAsync();
            try
            {
                var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken, includeOrganizationMember: true);
                if (user == null)
                {
                throw new NotFoundException("User not found");
            }

            var projectManager = await _unitOfWork.OrganizationMembers.GetByUserId(request.Dto.ProjectManagerId, cancellationToken);
            if (projectManager == null)
            {
                throw new NotFoundException("Project manager not found");
            }
            if (projectManager.Organization_IdOrganization != user.OrganizationMember.Organization_IdOrganization)
            {
                throw new UnauthorizedAccessException("Forbidden Access");
            }
            var project = new Project
            {
                Name = request.Dto.ProjectName,
                Description = request.Dto.ProjectDescription,
                Status = true,
                Organization_IdOrganization = projectManager.Organization_IdOrganization,
                ProjectManager_IdProjectManager = projectManager.Id,
            };
            var addedProject = await _unitOfWork.Projects.AddAsync(project, cancellationToken);
                await _unitOfWork.CompleteAsync();

                var projectPrivilege = new ProjectPrivilege
                {
                    Project_IdProject = addedProject.Id,
                    OrganizationMember_IdOrganizationMember = projectManager.Id,
                    Members = PrivilegeLevel.Write,
                    Meetings = PrivilegeLevel.Write,
                    Requirements = PrivilegeLevel.Write,
                    Tasks = PrivilegeLevel.Write,
                    Settings = PrivilegeLevel.Write,
                };
                await _unitOfWork.ProjectPrivileges.AddAsync(projectPrivilege);
                await _unitOfWork.CompleteAsync();
                await transaction.CommitAsync();
                return addedProject.Id;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

    }
}