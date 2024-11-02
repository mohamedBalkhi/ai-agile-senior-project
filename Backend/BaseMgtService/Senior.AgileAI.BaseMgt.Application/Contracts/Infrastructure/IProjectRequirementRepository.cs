using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IProjectRequirementRepository : IGenericRepository<ProjectRequirement>
{
    // ? Custom methods for ProjectRequirement repository
    Task<ProjectRequirement?> GetbyReqIdAsync(Guid id);

    Task<bool> AddRangeAsync(IEnumerable<ProjectRequirement> requirements);

    Task<bool> UpdateAsync(ProjectRequirement requirement);

    Task<List<ProjectRequirement>> GetByProjectId(Guid projectId);

    Task<bool> Delete(ProjectRequirement requirement);
}
