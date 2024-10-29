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
    public async Task<Project> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _context.Projects.Where(p => p.Id == id)
        .Include(p => p.ProjectManager)
        .ThenInclude(pm => pm.User)
        .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<Project> AddAsync(Project entity, CancellationToken cancellationToken)
    {
        var addedProject = await _context.Projects.AddAsync(entity, cancellationToken);
        return addedProject.Entity;
    }

    public async Task<List<Project>> GetAllByOrgAsync(Guid orgId, CancellationToken cancellationToken)
    {
        return await _context.Projects
        .Where(p => p.Organization_IdOrganization == orgId)
        .Include(p => p.ProjectManager)
        .ThenInclude(pm => pm.User)
        .ToListAsync(cancellationToken);
    }

    // Implement custom methods for Project repository
}