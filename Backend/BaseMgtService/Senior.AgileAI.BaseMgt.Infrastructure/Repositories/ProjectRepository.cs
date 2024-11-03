using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;


namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class ProjectRepository : GenericRepository<Project>, IProjectRepository
{
    public ProjectRepository(PostgreSqlAppDbContext context) : base(context)
    {

    }
#nullable disable
    public async Task<Project> GetByIdAsync(Guid id, CancellationToken cancellationToken, bool includeProjectManager = false)
    {
        var query = _context.Projects.AsQueryable();
        if (includeProjectManager)
            query = query.Include(p => p.ProjectManager).ThenInclude(pm => pm.User);
        return await query.Where(p => p.Id == id)
        .Include(p => p.ProjectManager)
        .ThenInclude(pm => pm.User)
        .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<Project> AddAsync(Project entity, CancellationToken cancellationToken)
    {
        var addedProject = await _context.Projects.AddAsync(entity, cancellationToken);
        return addedProject.Entity;
    }

    public async Task<List<Project>> GetAllByOrgAsync(Guid orgId, CancellationToken cancellationToken, bool includeProjectManager = false)
    {
        var query = _context.Projects.AsQueryable();
        if (includeProjectManager)
            query = query.Include(p => p.ProjectManager).ThenInclude(pm => pm.User);
        return await query
        .Where(p => p.Organization_IdOrganization == orgId && p.Status == true) // Only active projects
        .ToListAsync(cancellationToken);
    }

    public async Task<Project> GetProjectByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _context.Projects.FindAsync(id, cancellationToken);
    }

    public void UpdateProject(Project project)
    {
        _context.Projects.Update(project);
    }

    // Implement custom methods for Project repository
}