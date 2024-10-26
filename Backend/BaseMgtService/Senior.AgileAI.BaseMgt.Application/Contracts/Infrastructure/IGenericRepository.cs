using Senior.AgileAI.BaseMgt.Domain.Entities;
namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IGenericRepository<T> where T : BaseEntity
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    void Update(T entity);
    void Remove(T entity);
}