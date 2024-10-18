namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IUnitOfWork : IDisposable {
    IUserRepository Users { get; }
    ICountryRepository Countries { get; }
    IOrganizationRepository Organizations { get; }
    IProjectRepository Projects { get; }
    IOrganizationMemberRepository OrganizationMembers { get; }
    IProjectPrivilegeRepository ProjectPrivileges { get; }
    IProjectRequirementRepository ProjectRequirements { get; }
    

    Task<int> CompleteAsync();
}
