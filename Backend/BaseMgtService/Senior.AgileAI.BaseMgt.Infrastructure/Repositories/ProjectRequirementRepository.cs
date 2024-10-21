using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class ProjectRequirementRepository : GenericRepository<ProjectRequirement>, IProjectRequirementRepository
{
    public ProjectRequirementRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    // Implement custom methods for ProjectRequirement repository
}