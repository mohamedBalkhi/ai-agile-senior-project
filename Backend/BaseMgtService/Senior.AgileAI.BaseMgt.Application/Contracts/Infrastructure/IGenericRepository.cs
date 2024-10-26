using Senior.AgileAI.BaseMgt.Domain.Entities;
using System.Collections.Generic;
using System.Threading;
namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IGenericRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    void Update(T entity);
    void Remove(T entity);
    Task AddRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default);
}
