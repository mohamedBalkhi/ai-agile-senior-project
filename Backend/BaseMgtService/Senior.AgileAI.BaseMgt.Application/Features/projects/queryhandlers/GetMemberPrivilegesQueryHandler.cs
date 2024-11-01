using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Enums;
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
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken,includeOrganizationMember : true);
            if (user == null)
            {
                throw new NotFoundException("User not found");
            }
            var isAdmin = user.OrganizationMember.HasAdministrativePrivilege || user.OrganizationMember.IsManager;
            if (isAdmin)
            {
                // if the user is an admin, they have full access to all privileges
                return new MemberPrivilegesDto
                {
                    MeetingsPrivilegeLevel = PrivilegeLevel.Write.ToString(),
                    MembersPrivilegeLevel = PrivilegeLevel.Write.ToString(),
                    RequirementsPrivilegeLevel = PrivilegeLevel.Write.ToString(),
                    TasksPrivilegeLevel = PrivilegeLevel.Write.ToString(),
                    SettingsPrivilegeLevel = PrivilegeLevel.Write.ToString()
                };
            }
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