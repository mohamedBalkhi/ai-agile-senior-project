using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly PostgreSqlAppDbContext _context;

    public IUserRepository Users { get; private set; }
    public ICountryRepository Countries { get; private set; }
    public IOrganizationRepository Organizations { get; private set; }
    public IProjectRepository Projects { get; private set; }
    public IOrganizationMemberRepository OrganizationMembers { get; private set; }
    public IProjectPrivilegeRepository ProjectPrivileges { get; private set; }
    public IProjectRequirementRepository ProjectRequirements { get; private set; }

    public UnitOfWork(PostgreSqlAppDbContext context)
    {
        _context = context;
        Users = new UserRepository(_context);
        Countries = new CountryRepository(_context);
        Organizations = new OrganizationRepository(_context);
        Projects = new ProjectRepository(_context);
        OrganizationMembers = new OrganizationMemberRepository(_context);
        ProjectPrivileges = new ProjectPrivilegeRepository(_context);
        ProjectRequirements = new ProjectRequirementRepository(_context);
    }

    public async Task<int> CompleteAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}