using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Queries;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Filters;

using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.queryhandlers
{
    public class GetProjectRequirementsHandler : IRequestHandler<GetProjectRequirements, List<ProjectRequirementsDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public GetProjectRequirementsHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

#nullable disable

        public async Task<List<ProjectRequirementsDTO>> Handle(GetProjectRequirements request, CancellationToken cancellationToken)
        {
            var project = await _unitOfWork.Projects.GetByIdAsync(request.ProjectId);
            if (project == null)
                throw new NotFoundException("Project not found");

            var projectRequirements = await _unitOfWork.ProjectRequirements.GetByProjectIdPaginated(request.ProjectId, request.PageNumber, request.PageSize);
            projectRequirements = ApplyFilter(projectRequirements, request.Filter);
            return projectRequirements.Select(requirement => new ProjectRequirementsDTO
            {
                Id = requirement.Id,
                Title = requirement.Title,
                Description = requirement.Description,
                Priority = requirement.Priority,
                Status = requirement.Status
            }).ToList();
        }

        private List<ProjectRequirement> ApplyFilter(List<ProjectRequirement> projectRequirements, ProjectRequirementsFilter filter)
        {
            var filtered = projectRequirements;

            if (filter.Priority != null)
            {
                filtered = filtered.Where(r => r.Priority == filter.Priority).ToList();
            }
            if (filter.Status != null)
            {
                filtered = filtered.Where(r => r.Status == filter.Status).ToList();
            }

            return filtered;
        }
    }
}