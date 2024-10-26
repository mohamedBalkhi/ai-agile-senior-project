using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IOrganizationRepository : IGenericRepository<Organization>
{
    // ? Custom methods for Organization repository
    Task<Organization> AddOrganizationAsync(Organization organization, CancellationToken cancellationToken);
    Task<Organization> GetOrganizationByUserId(Guid userId, CancellationToken cancellationToken);

}
