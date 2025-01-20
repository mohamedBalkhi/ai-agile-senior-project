using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;


public class UserRepository : GenericRepository<User>, IUserRepository
{
    public UserRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }
    public async Task<User?> GetUserByEmailAsync(string email, bool includeRefreshTokens = false, bool includeOrganizationMember = false)
    {
        var query = _context.Users.AsQueryable();
        if (includeRefreshTokens)
            query = query.Include(u => u.RefreshTokens);
        if (includeOrganizationMember)
            query = query.Include(u => u.OrganizationMember);
        return await query.FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task<User?> GetUserByRefreshTokenAsync(string refreshToken)
    {
        return await _context.Users
            .Include(u => u.RefreshTokens)
            .Include(u => u.OrganizationMember)
            .FirstOrDefaultAsync(u => u.RefreshTokens.Any(rt => rt.Token == refreshToken));
    }
    public async Task<List<RefreshToken>?> GetUserAllRefreshTokensAsync(Guid userId, bool onlyIncludeTokenString = false, bool readOnly = false)
    {
        var query = _context.RefreshTokens.AsQueryable();

        if (readOnly)
        {
            query = query.AsNoTracking();
        }

        return onlyIncludeTokenString
            ? await query
                .Where(rt => rt.User_IdUser == userId)
                .Select(rt => new RefreshToken { Token = rt.Token })
                .ToListAsync()
            : await query
                .Where(rt => rt.User_IdUser == userId)
                .ToListAsync();
    }

    public async Task<User> AddAsync(User user, CancellationToken cancellationToken = default)
    {
        await _context.Users.AddAsync(user, cancellationToken);
        return user;
    }

    public User Update(User user, CancellationToken cancellationToken = default)
    {
        _context.Users.Update(user);
        return user;
    }
#nullable disable

    public async Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default, bool includeOrganizationMember = false, bool includeProjectPrivileges = false, bool includeOrganization = false, Guid? projectId = null)
    {
        var query = _context.Users.AsQueryable();
        if (includeOrganizationMember)
            query = query.Include(u => u.OrganizationMember);
        if (includeProjectPrivileges && includeOrganizationMember)
        {
            query = query.Include(u => u.OrganizationMember.ProjectPrivileges);
            if (projectId != null)
            query = query.Include(u => u.OrganizationMember.ProjectPrivileges.Where(pp => pp.Project_IdProject == projectId));
        }
        if (includeOrganization)
            query = query.Include(u => u.Organization);

        return await query.FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<User> GetProfileInformation(Guid id, CancellationToken cancellationToken)
    {
        // The error occurs because EF Core automatically fixes up navigation properties
        // when loading related data. In this case, trying to Include Organization again
        // through OrganizationMembers causes an invalid circular reference in the Include chain.
        
        // Instead, we should load the required navigation properties directly
        var user = await _context.Users
            .Where(u => u.Id == id)
            .Include(u => u.Country)
            .Include(u => u.Organization)
            .Include(u => u.OrganizationMember)
                .ThenInclude(om => om.Organization)
            .FirstOrDefaultAsync(cancellationToken);

        return user;
    }

    public async Task<User> getUserWithOrg(Guid id, CancellationToken cancellationToken)
    {
        var user = await _context.Users
            .Include(u => u.OrganizationMember).ThenInclude(om => om.Organization)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
        return user;
    }


}
