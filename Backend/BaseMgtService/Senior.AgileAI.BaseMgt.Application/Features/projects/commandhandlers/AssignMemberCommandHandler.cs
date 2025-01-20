using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Models;
using FluentValidation;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class AssignMemberCommandHandler : IRequestHandler<AssignMemberCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IProjectAuthorizationHelper _projectAuthorizationHelper;
        private readonly IRabbitMQService _rabbitMQService;

        public AssignMemberCommandHandler(IUnitOfWork unitOfWork, IProjectAuthorizationHelper projectAuthorizationHelper, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _projectAuthorizationHelper = projectAuthorizationHelper;
            _rabbitMQService = rabbitMQService;
        }

        public async Task<bool> Handle(AssignMemberCommand request, CancellationToken cancellationToken)
        {
            // get project first what if project not found
            var project = await _unitOfWork.Projects.GetByIdAsync(request.Dto.ProjectId, cancellationToken);
            if (project == null)
            {
                throw new NotFoundException("Project not found");
            }
            if (!await _projectAuthorizationHelper.HasProjectPrivilege(request.UserId, request.Dto.ProjectId, ProjectAspect.members, PrivilegeLevel.Write, cancellationToken))
            {
                throw new UnauthorizedAccessException("Forbidden Access");
            }
            var member = await _unitOfWork.OrganizationMembers.GetByUserId(request.Dto.MemberId, includeUser: true,cancellationToken);
            if (member == null)
            {
                throw new NotFoundException("Member not found");
            }
            // Check if member is already assigned to the project
            var existingPrivilege = await _unitOfWork.ProjectPrivileges.GetProjectPrivilegeByMember(member.Id, request.Dto.ProjectId, cancellationToken);
            if (existingPrivilege != null)
            {
                throw new ValidationException("Member already assigned to the project");
            }

            ProjectPrivilege newProjectPrivilege = new ProjectPrivilege
            {
                Project_IdProject = request.Dto.ProjectId,
                OrganizationMember_IdOrganizationMember = member.Id,
                Meetings = request.Dto.MeetingsPrivilegeLevel,
                Members = request.Dto.MembersPrivilegeLevel,
                Requirements = request.Dto.RequirementsPrivilegeLevel,
                Tasks = request.Dto.TasksPrivilegeLevel,
                Settings = request.Dto.SettingsPrivilegeLevel
            };

            var result = await _unitOfWork.ProjectPrivileges.AddPrivilegeAsync(newProjectPrivilege, cancellationToken);
            await _unitOfWork.CompleteAsync();

            // Get project name for notifications

            // Send email notification
            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = member.User.Email,
                Subject = $"Project Assignment: {project.Name}",
                Body = $"You have been assigned to project {project.Name}. Log in to view project details."
            });

            // Send FCM notification to all user's devices
            var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(member.User.Id, cancellationToken);
            foreach (var token in userTokens)
            {
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Firebase,
                    Recipient = token.Token,
                    Subject = "New Project Assignment",
                    Body = $"You've been added to {project.Name}"
                });
            }

            return result;
        }
    }
}