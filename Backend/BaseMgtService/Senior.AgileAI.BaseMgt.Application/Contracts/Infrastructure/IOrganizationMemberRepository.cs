using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IOrganizationMemberRepository : IGenericRepository<OrganizationMember>
{
    Task<OrganizationMember> AddOrganizationMemberAsync(OrganizationMember organizationMember, CancellationToken cancellationToken);
    Task<List<OrganizationMember>> GetByOrgId(Guid orgId, CancellationToken cancellationToken);
    Task<OrganizationMember> GetByUserId(Guid userId, CancellationToken cancellationToken, bool includeUser = false);
    Task<bool> DeleteAsync(OrganizationMember organizationMember, CancellationToken cancellationToken);
    Task<List<OrganizationMember>> GetByOrgIdPaginated(Guid orgId, int pageNumber, int pageSize, CancellationToken cancellationToken);
    // ? Custom methods for OrganizationMember repository
}
