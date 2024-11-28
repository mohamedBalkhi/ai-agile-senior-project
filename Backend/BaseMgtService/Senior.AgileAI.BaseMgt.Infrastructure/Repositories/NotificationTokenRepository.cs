using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class NotificationTokenRepository : GenericRepository<NotificationToken>, INotificationTokenRepository
{
    public NotificationTokenRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<NotificationToken?> GetByTokenAndDeviceId(string token, string deviceId, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationTokens
            .FirstOrDefaultAsync(nt => nt.Token == token && nt.DeviceId == deviceId, cancellationToken);
    }

    public async Task<List<NotificationToken>> GetTokensByUserId(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationTokens
            .Where(nt => nt.User_IdUser == userId)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> DeleteToken(string token, string deviceId, CancellationToken cancellationToken = default)
    {
        var tokenEntity = await GetByTokenAndDeviceId(token, deviceId, cancellationToken);
        if (tokenEntity == null) return false;
        
        _context.NotificationTokens.Remove(tokenEntity);
        return true;
    }

    public async Task<List<NotificationToken>> GetTokensToClean(CancellationToken cancellationToken = default)
    {
        var cutoffDate = DateTime.Now.AddMonths(-3); // Tokens older than 3 months
        return await _context.NotificationTokens
            .Where(nt => nt.UpdatedDate < cutoffDate)
            .ToListAsync(cancellationToken);
    }

    public async Task<int> GetUserTokenCount(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationTokens
            .CountAsync(nt => nt.User_IdUser == userId, cancellationToken);
    }

    public Task<bool> ValidateTokenFormat(string token)
    {
        // FCM tokens are typically ~150-160 characters
        if (string.IsNullOrWhiteSpace(token) || token.Length < 100 || token.Length > 250)
        {
            return Task.FromResult(false);
        }

        return Task.FromResult(true);
    }

    public new async Task<NotificationToken> AddAsync(NotificationToken entity)
    {
        await _context.NotificationTokens.AddAsync(entity);
        return entity;
    }
} 