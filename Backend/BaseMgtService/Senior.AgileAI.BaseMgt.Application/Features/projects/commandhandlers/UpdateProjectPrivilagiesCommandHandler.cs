using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class UpdateProjectPrivilagiesCommandHandler : IRequestHandler<UpdateProjectPrivilagiesCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IProjectAuthorizationHelper _projectAuthorizationHelper;
        public UpdateProjectPrivilagiesCommandHandler(IUnitOfWork unitOfWork, IProjectAuthorizationHelper projectAuthorizationHelper)
        {
            _unitOfWork = unitOfWork;
            _projectAuthorizationHelper = projectAuthorizationHelper;
        }
#nullable disable

        public async Task<bool> Handle(UpdateProjectPrivilagiesCommand request, CancellationToken cancellationToken)
        {
            if (!await _projectAuthorizationHelper.HasProjectPrivilege(request.UserId, request.Dto.ProjectId, ProjectAspect.members, PrivilegeLevel.Write, cancellationToken))
            {
                throw new UnauthorizedAccessException("Forbidden Access");
            }


            var projectPrivilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(request.Dto.MemberId, request.Dto.ProjectId, cancellationToken);
            if (projectPrivilege == null)
            {
                throw new ApplicationException("Project privilege not found");
            }

            if (request.Dto.MeetingsPrivilegeLevel.HasValue)
            {
                projectPrivilege.Meetings = request.Dto.MeetingsPrivilegeLevel.Value;
            }
            if (request.Dto.MembersPrivilegeLevel.HasValue)
            {
                projectPrivilege.Members = request.Dto.MembersPrivilegeLevel.Value;
            }
            if (request.Dto.RequirementsPrivilegeLevel.HasValue)
            {
                projectPrivilege.Requirements = request.Dto.RequirementsPrivilegeLevel.Value;
            }
            if (request.Dto.SettingsPrivilegeLevel.HasValue)
            {
                projectPrivilege.Settings = request.Dto.SettingsPrivilegeLevel.Value;
            }
            if (request.Dto.TasksPrivilegeLevel.HasValue)
            {
                projectPrivilege.Tasks = request.Dto.TasksPrivilegeLevel.Value;
            }

            await _unitOfWork.ProjectPrivileges.Update(projectPrivilege);
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