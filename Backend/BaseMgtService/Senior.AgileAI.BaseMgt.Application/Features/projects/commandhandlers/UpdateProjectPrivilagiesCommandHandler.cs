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
        public UpdateProjectPrivilagiesCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
#nullable disable

        public async Task<bool> Handle(UpdateProjectPrivilagiesCommand request, CancellationToken cancellationToken)
        {
            var projectPrivilege = await _unitOfWork.ProjectPrivileges.GetProjectPrivilegeByMember(request.Dto.MemberId, request.Dto.ProjectId, cancellationToken);
            if (projectPrivilege == null)
            {
                throw new ApplicationException("Project privilege not found");
            }

            if (request.Dto.MeetingsPrivilegeLevel != null)
            {
                projectPrivilege.Meetings = request.Dto.MeetingsPrivilegeLevel ?? 0;
            }
            if (request.Dto.MembersPrivilegeLevel != null)
            {
                projectPrivilege.Members = request.Dto.MembersPrivilegeLevel ?? 0;
            }
            if (request.Dto.RequirementsPrivilegeLevel != null)
            {
                projectPrivilege.Requirements = request.Dto.RequirementsPrivilegeLevel ?? 0; //none 
            }
            if (request.Dto.SettingsPrivilegeLevel != null)
            {
                projectPrivilege.Settings = request.Dto.SettingsPrivilegeLevel ?? 0; //none 
            }
            if (request.Dto.TasksPrivilegeLevel != null)
            {
                projectPrivilege.Tasks = request.Dto.TasksPrivilegeLevel ?? 0; //none 
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