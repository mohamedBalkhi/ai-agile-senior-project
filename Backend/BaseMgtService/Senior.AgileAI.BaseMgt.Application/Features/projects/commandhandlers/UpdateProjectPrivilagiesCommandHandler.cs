using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class UpdateProjectPrivilagiesCommandHandler : IRequestHandler<UpdateProjectPrivilagiesCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IProjectAuthorizationHelper _projectAuthorizationHelper;
        private readonly IRabbitMQService _rabbitMQService;

        public UpdateProjectPrivilagiesCommandHandler(
            IUnitOfWork unitOfWork, 
            IProjectAuthorizationHelper projectAuthorizationHelper,
            IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _projectAuthorizationHelper = projectAuthorizationHelper;
            _rabbitMQService = rabbitMQService;
        }

        public async Task<bool> Handle(UpdateProjectPrivilagiesCommand request, CancellationToken cancellationToken)
        {
            if (!await _projectAuthorizationHelper.HasProjectPrivilege(request.UserId, request.Dto.ProjectId, ProjectAspect.members, PrivilegeLevel.Write, cancellationToken))
            {
                throw new UnauthorizedAccessException("Forbidden Access");
            }

            var projectPrivilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(request.Dto.ProjectId, request.Dto.MemberId, cancellationToken);
            if (projectPrivilege == null)
            {
                throw new ApplicationException("Project privilege not found");
            }

            var project = await _unitOfWork.Projects.GetByIdAsync(request.Dto.ProjectId);
            var member = await _unitOfWork.Users.GetByIdAsync(request.Dto.MemberId);

            if (request.Dto.MeetingsPrivilegeLevel.HasValue)
                projectPrivilege.Meetings = request.Dto.MeetingsPrivilegeLevel.Value;
            if (request.Dto.MembersPrivilegeLevel.HasValue)
                projectPrivilege.Members = request.Dto.MembersPrivilegeLevel.Value;
            if (request.Dto.RequirementsPrivilegeLevel.HasValue)
                projectPrivilege.Requirements = request.Dto.RequirementsPrivilegeLevel.Value;
            if (request.Dto.SettingsPrivilegeLevel.HasValue)
                projectPrivilege.Settings = request.Dto.SettingsPrivilegeLevel.Value;
            if (request.Dto.TasksPrivilegeLevel.HasValue)
                projectPrivilege.Tasks = request.Dto.TasksPrivilegeLevel.Value;

            await _unitOfWork.ProjectPrivileges.Update(projectPrivilege);

            var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(member.Id, cancellationToken);
            foreach (var token in userTokens)
            {
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Firebase,
                    Recipient = token.Token,
                    Subject = "Project Access Updated",
                    Body = $"Your access levels in {project.Name} have been updated"
                });
            }

            try
            {
                await _unitOfWork.CompleteAsync();
                return true;
            }
            catch (InvalidOperationException ex) when (ex.Message.Contains("concurrent"))
            {
                throw new ApplicationException("The project privileges are being modified by another operation. Please try again.", ex);
            }
        }
    }
}