using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

public class CalendarSubscriptionCleanupWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CalendarSubscriptionCleanupWorker> _logger;
    private readonly TimeSpan _processInterval = TimeSpan.FromHours(24); // Run daily
    private const int BatchSize = 100;

    public CalendarSubscriptionCleanupWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<CalendarSubscriptionCleanupWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("{ServiceName} starting", nameof(CalendarSubscriptionCleanupWorker));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessExpiredSubscriptionsAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("{ServiceName} stopping", nameof(CalendarSubscriptionCleanupWorker));
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in {ServiceName}", nameof(CalendarSubscriptionCleanupWorker));
            }

            await Task.Delay(_processInterval, stoppingToken);
        }
    }

    private async Task ProcessExpiredSubscriptionsAsync(CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

        var cutoffDate = DateTime.UtcNow;
        var expiredSubscriptions = await unitOfWork.CalendarSubscriptions
            .GetExpiredSubscriptionsAsync(cutoffDate, stoppingToken);

        if (!expiredSubscriptions.Any())
        {
            _logger.LogInformation("No expired subscriptions found at {Time}", DateTime.UtcNow);
            return;
        }

        foreach (var subscription in expiredSubscriptions)
        {
            subscription.IsActive = false;
            unitOfWork.CalendarSubscriptions.Update(subscription);
        }
        

        await unitOfWork.CompleteAsync();
        _logger.LogInformation(
            "Deactivated {Count} expired calendar subscriptions at {Time}", 
            expiredSubscriptions.Count,
            DateTime.UtcNow);
    }
} 