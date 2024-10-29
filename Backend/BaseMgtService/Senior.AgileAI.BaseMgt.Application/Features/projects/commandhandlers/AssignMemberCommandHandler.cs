using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;


namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class AssignMemberCommandHandler : IRequestHandler<AssignMemberCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;

        public AssignMemberCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(AssignMemberCommand request, CancellationToken cancellationToken)
        {
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