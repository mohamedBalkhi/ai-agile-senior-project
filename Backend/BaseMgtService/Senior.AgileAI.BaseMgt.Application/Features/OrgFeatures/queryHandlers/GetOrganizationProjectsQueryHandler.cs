using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.queryHandlers
{
    public class GetOrganizationProjectsQueryHandler : IRequestHandler<GetOrganizationProjectsQuery, List<GetOrgProjectDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetOrganizationProjectsQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
#nullable disable
        public async Task<List<GetOrgProjectDTO>> Handle(GetOrganizationProjectsQuery request, CancellationToken cancellationToken)
        {
            var User = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken, includeOrganization : true,includeOrganizationMember: true);
            var Organization = User.Organization?.Id ?? User.OrganizationMember.Organization_IdOrganization;

            var projects = await _unitOfWork.Projects.GetAllByOrgAsync(Organization, cancellationToken);
            return projects.Select(p => new GetOrgProjectDTO
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                CreatedAt = p.CreatedDate,
                ProjectManager = p.ProjectManager.User.FUllName,
            }).ToList();
        }
    }
}