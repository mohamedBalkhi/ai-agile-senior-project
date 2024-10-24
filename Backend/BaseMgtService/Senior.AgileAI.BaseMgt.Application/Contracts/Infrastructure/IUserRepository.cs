using Senior.AgileAI.BaseMgt.Domain.Entities;
using System.Threading;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IUserRepository : IGenericRepository<User>
{
    // ? Custom methods for User repository
    Task<User?> GetUserByEmailAsync(string email, bool includeRefreshTokens = false, bool includeOrganizationMember = false);
    Task<User?> GetUserByRefreshTokenAsync(string refreshToken);

    Task<List<RefreshToken>?> GetUserAllRefreshTokensAsync(Guid userId, bool onlyIncludeTokenString = false, bool readOnly = false);

    // New method for adding a user
    Task<User> AddAsync(User user, CancellationToken cancellationToken = default);

    User Update(User user, CancellationToken cancellationToken = default);
    Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
