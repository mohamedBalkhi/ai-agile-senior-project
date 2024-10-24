using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IOrganizationMemberRepository : IGenericRepository<OrganizationMember> {
    Task<OrganizationMember> AddOrganizationMemberAsync(OrganizationMember organizationMember, CancellationToken cancellationToken);
    // ? Custom methods for OrganizationMember repository
}
