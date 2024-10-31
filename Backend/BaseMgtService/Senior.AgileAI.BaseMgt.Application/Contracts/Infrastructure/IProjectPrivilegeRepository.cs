using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IProjectPrivilegeRepository : IGenericRepository<ProjectPrivilege>
{
    Task<ProjectPrivilege?> GetPrivilegeByUserIdAsync(
        Guid projectId,
        Guid userId,
        CancellationToken cancellationToken = default
    );
    Task<List<ProjectPrivilege>> GetProjectMembersAsync(Guid projectId, CancellationToken cancellationToken = default);
    Task<bool> AddPrivilegeAsync(ProjectPrivilege privilege, CancellationToken cancellationToken = default);
    Task<List<ProjectPrivilege>> GetProjectsByMember(OrganizationMember organizationMember, CancellationToken cancellationToken = default);
}
