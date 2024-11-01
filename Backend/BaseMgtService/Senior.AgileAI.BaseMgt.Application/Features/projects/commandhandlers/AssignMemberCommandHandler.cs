using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Domain.Enums;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class AssignMemberCommandHandler : IRequestHandler<AssignMemberCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IProjectAuthorizationHelper _projectAuthorizationHelper;

        public AssignMemberCommandHandler(IUnitOfWork unitOfWork, IProjectAuthorizationHelper projectAuthorizationHelper)
        {
            _unitOfWork = unitOfWork;
            _projectAuthorizationHelper = projectAuthorizationHelper;
        }

        public async Task<bool> Handle(AssignMemberCommand request, CancellationToken cancellationToken)
        {
            if (!await _projectAuthorizationHelper.HasProjectPrivilege(request.UserId, request.Dto.ProjectId, ProjectAspect.members, PrivilegeLevel.Write, cancellationToken))
            {
                throw new UnauthorizedAccessException("Forbidden Access");
            }
            ProjectPrivilege newProjectPrivilege = new ProjectPrivilege
            {
                Project_IdProject = request.Dto.ProjectId,
                OrganizationMember_IdOrganizationMember = request.Dto.MemberId,
                Meetings = request.Dto.MeetingsPrivilegeLevel,
                Members = request.Dto.MembersPrivilegeLevel,
                Requirements = request.Dto.RequirementsPrivilegeLevel,
                Tasks = request.Dto.TasksPrivilegeLevel,
                Settings = request.Dto.SettingsPrivilegeLevel
            };

            var result = await _unitOfWork.ProjectPrivileges.AddPrivilegeAsync(newProjectPrivilege, cancellationToken);
            await _unitOfWork.CompleteAsync();
            return result;
        }
    }
}