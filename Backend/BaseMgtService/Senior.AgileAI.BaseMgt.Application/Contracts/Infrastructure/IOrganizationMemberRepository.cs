using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IOrganizationMemberRepository : IGenericRepository<OrganizationMember>
{
    Task<OrganizationMember> GetByIdAsync(Guid id, bool includeUser = false, CancellationToken cancellationToken = default);
    Task<OrganizationMember> AddOrganizationMemberAsync(OrganizationMember organizationMember, CancellationToken cancellationToken);
    Task<List<OrganizationMember>> GetByOrgId(Guid orgId, CancellationToken cancellationToken);
    Task<OrganizationMember> GetByUserId(Guid userId, bool includeUser = false, CancellationToken cancellationToken = default);
    Task<List<OrganizationMember>> GetAllMembersAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(OrganizationMember organizationMember, CancellationToken cancellationToken);
    Task<List<OrganizationMember>> GetByOrgIdPaginated(Guid orgId, int pageNumber, int pageSize, CancellationToken cancellationToken);
    // ? Custom methods for OrganizationMember repository
}
