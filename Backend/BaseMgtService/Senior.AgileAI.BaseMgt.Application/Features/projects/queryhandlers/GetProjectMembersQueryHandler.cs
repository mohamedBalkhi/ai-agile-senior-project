using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.queryhandlers
{
    public class GetProjectMembersQueryHandler : IRequestHandler<GetProjectMembersQuery, List<ProjectMemberDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public GetProjectMembersQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<List<ProjectMemberDTO>> Handle(GetProjectMembersQuery request, CancellationToken cancellationToken)
        {
            var projectMembers = await _unitOfWork.ProjectPrivileges.GetProjectMembersAsync(request.ProjectId, cancellationToken);

            var projectMembersDTOs = projectMembers.Select(pm => new ProjectMemberDTO
            {
                UserId = pm.OrganizationMember.User.Id,
                MemberId= pm.OrganizationMember_IdOrganizationMember, //needed for other endpoints
                Name = pm.OrganizationMember.User.FUllName,
                Email = pm.OrganizationMember.User.Email,
                Meetings = pm.Meetings.ToString(),
                Members = pm.Members.ToString(),
                Requirements = pm.Requirements.ToString(), // to return the name of the privilege level.
                Tasks = pm.Tasks.ToString(),
                Settings = pm.Settings.ToString()
            }).ToList();

            return projectMembersDTOs;
        }
    }
}