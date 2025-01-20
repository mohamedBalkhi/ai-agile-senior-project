using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

public class RecurringMeetingGeneratorWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<RecurringMeetingGeneratorWorker> _logger;
    private readonly TimeSpan _processInterval = TimeSpan.FromHours(1);

    public RecurringMeetingGeneratorWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<RecurringMeetingGeneratorWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("{ServiceName} starting", nameof(RecurringMeetingGeneratorWorker));

        while (!stoppingToken.IsCancellationRequested)
        {
            using var scope = _scopeFactory.CreateScope();
            var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var recurringService = scope.ServiceProvider.GetRequiredService<IRecurringMeetingService>();

            try
            {
                // Get active patterns that aren't cancelled
                var patterns = await unitOfWork.RecurringMeetingPatterns
                    .GetActivePatternsAsync(DateTime.UtcNow, stoppingToken);

                foreach (var pattern in patterns.Where(p => !p.IsCancelled))
                {
                    // Count existing future instances
                    var futureInstances = await unitOfWork.Meetings
                        .GetFutureRecurringInstances(pattern.Id, DateTime.UtcNow, stoppingToken);

                    if (futureInstances.Count < RecurringMeetingPattern.MaxFutureInstances)
                    {
                        _logger.LogInformation(
                            "Generating instances for pattern {PatternId}. Current count: {Count}", 
                            pattern.Id, 
                            futureInstances.Count);

                        await recurringService.GenerateFutureInstances(
                            pattern.Meeting, 
                            DateTime.UtcNow.AddMonths(1));

                        pattern.LastGeneratedDate = DateTime.UtcNow;
                    }
                }

                await unitOfWork.CompleteAsync();
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("{ServiceName} stopping", nameof(RecurringMeetingGeneratorWorker));
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in {ServiceName}", nameof(RecurringMeetingGeneratorWorker));
            }

            await Task.Delay(_processInterval, stoppingToken);
        }
    }
} 