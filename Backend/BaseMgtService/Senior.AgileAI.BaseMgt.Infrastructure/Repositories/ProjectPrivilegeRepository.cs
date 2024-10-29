using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class ProjectPrivilegeRepository : GenericRepository<ProjectPrivilege>, IProjectPrivilegeRepository
{
    public ProjectPrivilegeRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<ProjectPrivilege?> GetPrivilegeAsync(
        Guid projectId,
        Guid organizationMemberId,
        CancellationToken cancellationToken = default)
    {
        return await _context.ProjectPrivileges
            .FirstOrDefaultAsync(pp =>
                pp.Project_IdProject == projectId &&
                pp.OrganizationMember_IdOrganizationMember == organizationMemberId,
                cancellationToken);
    }

    public async Task<bool> AddPrivilegeAsync(ProjectPrivilege privilege, CancellationToken cancellationToken = default)
    {
        await _context.ProjectPrivileges.AddAsync(privilege, cancellationToken);
        return await _context.SaveChangesAsync(cancellationToken) > 0;
    }

    public async Task<List<ProjectPrivilege>> GetProjectMembersAsync(Guid projectId, CancellationToken cancellationToken = default)
    {
        return await _context.ProjectPrivileges
            .Where(pp => pp.Project_IdProject == projectId)
            .Include(pp => pp.OrganizationMember).ThenInclude(om => om.User)
            .ToListAsync(cancellationToken);
    }

    // Implement custom methods for ProjectPrivilege repository
}