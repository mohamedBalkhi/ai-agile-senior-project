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

    public async Task<ProjectPrivilege?> GetPrivilegeByUserIdAsync(
        Guid projectId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        return await _context.ProjectPrivileges
            .FirstOrDefaultAsync(pp =>
                pp.Project_IdProject == projectId &&
                pp.OrganizationMember.User_IdUser == userId,
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

    public async Task<List<ProjectPrivilege>> GetProjectsByMember(OrganizationMember organizationMember, CancellationToken cancellationToken = default)
    {
        return await _context.ProjectPrivileges
            .Where(pp => pp.OrganizationMember_IdOrganizationMember == organizationMember.Id)
            .Include(pp => pp.Project)
            .ToListAsync(cancellationToken);
    }

    public async Task Update(ProjectPrivilege privilege, CancellationToken cancellationToken = default)
    {
        _context.ProjectPrivileges.Update(privilege);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<ProjectPrivilege> GetProjectPrivilegeByMember(Guid organizationMemberId, Guid projectId, CancellationToken cancellationToken = default)
    {
        return await _context.ProjectPrivileges
            .Where(pp => pp.OrganizationMember_IdOrganizationMember == organizationMemberId && pp.Project_IdProject == projectId)
            .Include(pp => pp.Project)
            .FirstOrDefaultAsync(cancellationToken);
    }

#nullable disable

    // Implement custom methods for ProjectPrivilege repository
}