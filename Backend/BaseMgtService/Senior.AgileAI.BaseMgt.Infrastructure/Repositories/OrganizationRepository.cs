using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class OrganizationRepository : GenericRepository<Organization>, IOrganizationRepository
{
    public OrganizationRepository(PostgreSqlAppDbContext context) : base(context)
    {

    }

    public async Task<Organization> AddOrganizationAsync(Organization organization, CancellationToken cancellationToken)
    {
        await _context.Organizations.AddAsync(organization, cancellationToken);
        return organization;
    }

    // Implement custom methods for Organization repository
}