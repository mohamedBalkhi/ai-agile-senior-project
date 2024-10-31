using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using MediatR;
namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queryhandlers
{
    public class GetMemberPrivilegesQueryHandler : IRequestHandler<GetMemberPrivilegesQuery, MemberPrivilegesDto>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetMemberPrivilegesQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
#nullable disable
        public async Task<MemberPrivilegesDto> Handle(GetMemberPrivilegesQuery request, CancellationToken cancellationToken)
        {
            ProjectPrivilege projectPrivilege = await _unitOfWork.ProjectPrivileges.GetPrivilegeByUserIdAsync(request.ProjectId, request.UserId, cancellationToken);
            var memberPrivileges = new MemberPrivilegesDto
            {
                MeetingsPrivilegeLevel = projectPrivilege.Meetings.ToString(),
                MembersPrivilegeLevel = projectPrivilege.Members.ToString(),
                RequirementsPrivilegeLevel = projectPrivilege.Requirements.ToString(),
                TasksPrivilegeLevel = projectPrivilege.Tasks.ToString(),
                SettingsPrivilegeLevel = projectPrivilege.Settings.ToString()
            };
            return memberPrivileges;
        }
    }
}