using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IProjectRequirementRepository : IGenericRepository<ProjectRequirement>
{
    // ? Custom methods for ProjectRequirement repository
    Task<ProjectRequirement?> GetbyReqIdAsync(Guid id);

    Task<bool> AddRangeAsync(IEnumerable<ProjectRequirement> requirements);

    Task<bool> UpdateAsync(ProjectRequirement requirement);

    Task<List<ProjectRequirement>> GetByProjectIdPaginated(
        Guid projectId, 
        int pageNumber, 
        int pageSize,
        ReqPriority? priority = null,
        RequirementsStatus? status = null,
        string? searchQuery = null);

    Task<bool> Delete(ProjectRequirement requirement);
}
