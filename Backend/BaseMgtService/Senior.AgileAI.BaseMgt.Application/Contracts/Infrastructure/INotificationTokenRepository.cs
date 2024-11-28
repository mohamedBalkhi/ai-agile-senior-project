using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface INotificationTokenRepository : IGenericRepository<NotificationToken>
{
    Task<NotificationToken?> GetByTokenAndDeviceId(string token, string deviceId, CancellationToken cancellationToken = default);
    Task<List<NotificationToken>> GetTokensByUserId(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> DeleteToken(string token, string deviceId, CancellationToken cancellationToken = default);
    Task<List<NotificationToken>> GetTokensToClean(CancellationToken cancellationToken = default);
    Task<int> GetUserTokenCount(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> ValidateTokenFormat(string token);
} 