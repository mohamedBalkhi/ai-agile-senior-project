using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class CreateProjectCommandHandler : IRequestHandler<CreateProjectCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;

        public CreateProjectCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
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

            var projectManager = await _unitOfWork.OrganizationMembers.GetByUserId(request.Dto.ProjectManagerId, includeUser: true, cancellationToken);
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
                await _unitOfWork.ProjectPrivileges.AddAsync(projectPrivilege, cancellationToken);
                await _unitOfWork.CompleteAsync();

                // Send email notification to project manager
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Email,
                    Recipient = projectManager.User.Email,
                    Subject = $"New Project Created: {project.Name}",
                    Body = $"You have been assigned as manager to new project: {project.Name}"
                });

                // Send FCM notification
                var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(projectManager.User.Id, cancellationToken);
                foreach (var token in userTokens)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Firebase,
                        Recipient = token.Token,
                        Subject = "New Project Created",
                        Body = $"You're now managing: {project.Name}"
                    });
                }

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