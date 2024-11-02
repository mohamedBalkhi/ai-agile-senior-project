using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class ProjectRequirementRepository : GenericRepository<ProjectRequirement>, IProjectRequirementRepository
{
    public ProjectRequirementRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<ProjectRequirement?> GetbyReqIdAsync(Guid id)
    {
        return await _context.ProjectRequirements
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == id);
    }

    public async Task<bool> AddRangeAsync(IEnumerable<ProjectRequirement> requirements)
    {
        await _context.ProjectRequirements.AddRangeAsync(requirements);
        return await _context.SaveChangesAsync() > 0;
    }

    public async Task<bool> UpdateAsync(ProjectRequirement requirement)
    {
        _context.ProjectRequirements.Update(requirement);
        return await _context.SaveChangesAsync() > 0;
    }

    public async Task<List<ProjectRequirement>> GetByProjectIdPaginated(Guid projectId, int pageNumber, int pageSize)
    {
        return await _context.ProjectRequirements
            .Where(r => r.Project_IdProject == projectId)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize).OrderBy(r => r.CreatedDate)
            .ToListAsync();
    }



    public async Task<bool> Delete(ProjectRequirement requirement)
    {
        _context.ProjectRequirements.Remove(requirement);
        return await _context.SaveChangesAsync() > 0;
    }

    // Implement custom methods for ProjectRequirement repository
}