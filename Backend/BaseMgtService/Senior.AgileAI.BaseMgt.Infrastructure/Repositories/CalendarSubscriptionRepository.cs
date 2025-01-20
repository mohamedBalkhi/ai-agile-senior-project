using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class CalendarSubscriptionRepository : GenericRepository<CalendarSubscription>, ICalendarSubscriptionRepository
{
    private readonly PostgreSqlAppDbContext _dbContext;

    public CalendarSubscriptionRepository(PostgreSqlAppDbContext context) : base(context)
    {
        _dbContext = context;
    }

    public async Task<CalendarSubscription?> GetByTokenAsync(
        string token, 
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<CalendarSubscription>()
            .Include(cs => cs.User)
            .Include(cs => cs.Project)
            .Include(cs => cs.RecurringPattern)
            .FirstOrDefaultAsync(cs => cs.Token == token && cs.IsActive, cancellationToken);
    }

    public async Task<List<CalendarSubscription>> GetActiveByUserIdAsync(
        Guid userId, 
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<CalendarSubscription>()
            .Include(cs => cs.Project)
            .Include(cs => cs.RecurringPattern)
            .Where(cs => cs.User_IdUser == userId && cs.IsActive)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> IsTokenUniqueAsync(
        string token, 
        CancellationToken cancellationToken = default)
    {
        return !await _dbContext.Set<CalendarSubscription>()
            .AnyAsync(cs => cs.Token == token, cancellationToken);
    }

    public async Task<List<CalendarSubscription>> GetExpiredSubscriptionsAsync(
        DateTime cutoffDate, 
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<CalendarSubscription>()
            .Where(cs => cs.IsActive && cs.ExpiresAt <= cutoffDate)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<CalendarSubscription>> GetByProjectIdAsync(
        Guid projectId, 
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<CalendarSubscription>()
            .Include(cs => cs.User)
            .Where(cs => cs.Project_IdProject == projectId && cs.IsActive)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<CalendarSubscription>> GetByRecurringPatternIdAsync(
        Guid patternId, 
        CancellationToken cancellationToken = default)
    {
        return await _dbContext.Set<CalendarSubscription>()
            .Include(cs => cs.User)
            .Where(cs => cs.RecurringPattern_IdRecurringPattern == patternId && cs.IsActive)
            .ToListAsync(cancellationToken);
    }
} 