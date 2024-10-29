using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IProjectRepository : IGenericRepository<Project>
{
    // ? Custom methods for Project repository
    Task<Project> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<List<Project>> GetAllByOrgAsync(Guid orgId, CancellationToken cancellationToken);
    Task<Project> AddAsync(Project entity, CancellationToken cancellationToken);
}
