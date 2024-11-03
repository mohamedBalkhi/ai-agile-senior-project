using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IProjectRepository : IGenericRepository<Project>
{
    // ? Custom methods for Project repository
    Task<Project> GetByIdAsync(Guid id, CancellationToken cancellationToken, bool includeProjectManager = false);
    Task<List<Project>> GetAllByOrgAsync(Guid orgId, CancellationToken cancellationToken, bool includeProjectManager = false);
    Task<Project> AddAsync(Project entity, CancellationToken cancellationToken);
    Task<Project> GetProjectByIdAsync(Guid id, CancellationToken cancellationToken);
    void UpdateProject(Project project);

    
}
