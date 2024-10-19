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
}