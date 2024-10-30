using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

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

    public async Task<List<OrganizationMember>> GetByOrgId(Guid orgId, CancellationToken cancellationToken)
    {
        return await _context.OrganizationMembers
            .Where(om => om.Organization_IdOrganization == orgId)
            .Include(om => om.User)
            .Include(om => om.ProjectPrivileges)
            .ThenInclude(pp => pp.Project)
            .ToListAsync(cancellationToken);
    }
#nullable disable

    public async Task<OrganizationMember> GetByUserId(Guid userId, CancellationToken cancellationToken, bool includeUser)
    {
        var query = _context.OrganizationMembers.AsQueryable();
        if (includeUser)
            query = query.Include(om => om.User);
        return await query
            .Where(om => om.User_IdUser == userId)
            .FirstOrDefaultAsync(cancellationToken);
    }

}
