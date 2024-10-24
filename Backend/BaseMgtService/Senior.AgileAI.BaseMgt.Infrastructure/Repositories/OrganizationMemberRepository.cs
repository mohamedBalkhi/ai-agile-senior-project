using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class OrganizationMemberRepository : GenericRepository<OrganizationMember>, IOrganizationMemberRepository
{
    public OrganizationMemberRepository(PostgreSqlAppDbContext context) : base(context)
    {

    }

    public async Task<OrganizationMember> AddOrganizationMemberAsync(OrganizationMember organizationMember, CancellationToken cancellationToken)
    {
        await _context.OrganizationMembers.AddAsync(organizationMember, cancellationToken);
        return organizationMember;
    }

    // Implement custom methods for OrganizationMember repository
}