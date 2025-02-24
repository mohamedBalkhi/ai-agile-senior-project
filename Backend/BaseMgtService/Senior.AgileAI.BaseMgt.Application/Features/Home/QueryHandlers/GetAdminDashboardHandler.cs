using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Home.Queries;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Home.QueryHandlers
{
    public class GetAdminDashboardHandler : IRequestHandler<GetAdminDashboard, AdminDashboardDto>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetAdminDashboardHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<AdminDashboardDto> Handle(GetAdminDashboard request, CancellationToken cancellationToken)
        {
            var organizations = await _unitOfWork.Organizations.GetAllAsync(cancellationToken);
            var orgsList = organizations.ToList();
            var orgCount = orgsList.Count;

            var users = await _unitOfWork.Users.GetAllAsync(cancellationToken);
            var userCount = users.Count();

            var chartOne = orgsList.Select(org => new OrgCreationDate
            {
                OrgId = org.Id,
                OrgName = org.Name,
                CreatedDate = org.CreatedDate
            }).ToList();

            var chartTwo = orgsList.Select(org => new ProjectsPerOrg
            {
                OrgId = org.Id,
                OrgName = org.Name,
                ProjectsNo = org.Projects?.Count ?? 0
            }).ToList();

            var chartThree = orgsList.Select(org => new MembersPerOrg
            {
                OrgId = org.Id,
                OrgName = org.Name,
                MembersNo = org.OrganizationMembers?.Count ?? 0
            }).ToList();

            return new AdminDashboardDto
            {
                UsersCount = userCount,
                OrgCount = orgCount,
                ChartOne = chartOne,
                ChartTwo = chartTwo,
                ChartThree = chartThree
            };
        }
    }
}