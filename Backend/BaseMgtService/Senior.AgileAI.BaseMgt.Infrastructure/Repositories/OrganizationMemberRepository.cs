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

    #nullable disable
    public async Task<OrganizationMember> GetByIdAsync(Guid id, bool includeUser = false, CancellationToken cancellationToken = default)
    {
        var query = _context.OrganizationMembers.AsQueryable();
        if (includeUser)
            query = query.Include(om => om.User);
        return await query.FirstOrDefaultAsync(om => om.Id == id, cancellationToken);
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

    public async Task<OrganizationMember> GetByUserId(Guid userId, bool includeUser = false, CancellationToken cancellationToken = default)
    {
        var query = _context.OrganizationMembers.AsQueryable();
        if (includeUser)
            query = query.Include(om => om.User);
        return await query
            .Where(om => om.User_IdUser == userId)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<List<OrganizationMember>> GetAllMembersAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        return await _context.OrganizationMembers
            .Include(om => om.User)
            .Where(om => om.Organization_IdOrganization == organizationId)
            .ToListAsync(cancellationToken);
    }
    public async Task<List<OrganizationMember>> GetByOrgIdPaginated(Guid orgId, int pageNumber = 1, int pageSize = 10, CancellationToken cancellationToken = default)
    {
        return await _context.OrganizationMembers
            .Where(om => om.Organization_IdOrganization == orgId)
            .Include(om => om.User)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

    }

    public async Task<bool> DeleteAsync(OrganizationMember organizationMember, CancellationToken cancellationToken)
    {
        _context.OrganizationMembers.Remove(organizationMember);
        return await _context.SaveChangesAsync(cancellationToken) > 0;
    }

    public async Task<OrganizationMember?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.OrganizationMembers
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken);
    }

}
