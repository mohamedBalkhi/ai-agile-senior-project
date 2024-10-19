using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IUserRepository : IGenericRepository<User> {
    // ? Custom methods for User repository
    Task<User?> GetUserByEmailAsync(string email, bool includeRefreshTokens = false, bool includeOrganizationMember = false);
    Task<User?> GetUserByRefreshTokenAsync(string refreshToken);
}
