using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class ProjectPrivilegeRepository : GenericRepository<ProjectPrivilege>, IProjectPrivilegeRepository
{
    public ProjectPrivilegeRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    // Implement custom methods for ProjectPrivilege repository
}