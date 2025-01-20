using Senior.AgileAI.BaseMgt.Domain.Entities;
using System.Collections.Generic;
using System.Threading;
namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IGenericRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
    void Update(T entity);
    void Remove(T entity);
    Task AddRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default);
}
