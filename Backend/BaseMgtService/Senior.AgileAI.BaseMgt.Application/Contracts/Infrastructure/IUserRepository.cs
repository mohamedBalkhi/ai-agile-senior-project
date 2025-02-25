using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.DTOs;

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
    Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default, bool includeOrganizationMember = false, bool includeProjectPrivileges = false, bool includeOrganization = false, Guid? projectId = null);
    Task<User> GetProfileInformation(Guid id, CancellationToken cancellationToken);
    Task<User> getUserWithOrg(Guid id, CancellationToken cancellationToken);
    Task<List<User>> GetUsersAsync(int pageSize, int pageNumber, GetUsersFilter? filter = null, CancellationToken cancellationToken = default);
}
