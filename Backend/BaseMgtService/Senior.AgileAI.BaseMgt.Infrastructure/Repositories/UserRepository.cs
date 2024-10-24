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

    public async Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Users.FindAsync(id, cancellationToken);
    }


}
