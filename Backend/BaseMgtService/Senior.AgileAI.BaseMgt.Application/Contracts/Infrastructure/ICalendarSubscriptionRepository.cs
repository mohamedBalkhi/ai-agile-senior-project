using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface ICalendarSubscriptionRepository : IGenericRepository<CalendarSubscription>
{
    Task<CalendarSubscription?> GetByTokenAsync(string token, CancellationToken cancellationToken = default);
    Task<List<CalendarSubscription>> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> IsTokenUniqueAsync(string token, CancellationToken cancellationToken = default);
    Task<List<CalendarSubscription>> GetExpiredSubscriptionsAsync(DateTime cutoffDate, CancellationToken cancellationToken = default);
    Task<List<CalendarSubscription>> GetByProjectIdAsync(Guid projectId, CancellationToken cancellationToken = default);
    Task<List<CalendarSubscription>> GetByRecurringPatternIdAsync(Guid patternId, CancellationToken cancellationToken = default);
} 