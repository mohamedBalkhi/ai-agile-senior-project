using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Domain.Enums;

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

    public async Task<List<ProjectRequirement>> GetByProjectIdPaginated(
        Guid projectId, 
        int pageNumber, 
        int pageSize,
        ReqPriority? priority = null,
        RequirementsStatus? status = null,
        string? searchQuery = null)
    {
        var query = _context.ProjectRequirements
            .Where(r => r.Project_IdProject == projectId);

        if (priority.HasValue)
        {
            query = query.Where(r => r.Priority == priority.Value);
        }

        if (status.HasValue)
        {
            query = query.Where(r => r.Status == status.Value);
        }

        if (!string.IsNullOrWhiteSpace(searchQuery))
        {
            var searchTerm = searchQuery.Trim().ToLower();
            query = query.Where(r => 
                EF.Functions.ILike(r.Title, $"%{searchTerm}%") || 
                EF.Functions.ILike(r.Description, $"%{searchTerm}%"));
        }

        return await query
            .OrderBy(r => r.CreatedDate)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<bool> Delete(ProjectRequirement requirement)
    {
        _context.ProjectRequirements.Remove(requirement);
        return await _context.SaveChangesAsync() > 0;
    }

    // Implement custom methods for ProjectRequirement repository
}