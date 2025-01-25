using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.Hosting;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices
{
    public class MeetingStatusWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<MeetingStatusWorker> _logger;
        private readonly TimeSpan _processInterval = TimeSpan.FromMinutes(5);
        private const int BatchSize = 100;

        public MeetingStatusWorker(IServiceScopeFactory scopeFactory, ILogger<MeetingStatusWorker> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("{ServiceName} starting", nameof(MeetingStatusWorker));

            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

                try
                {
                    var inProgressMeetings = await unitOfWork.Meetings.GetMeetingsToCompleteAsync(
                        DateTime.UtcNow,
                        BatchSize,
                        stoppingToken);

                    foreach (var meeting in inProgressMeetings)
                    {
                        meeting.Complete();
                    }

                    if (inProgressMeetings.Any())
                    {
                        await unitOfWork.CompleteAsync();
                        _logger.LogInformation(
                            "Completed {Count} meetings at {Time} UTC", 
                            inProgressMeetings.Count,
                            DateTime.UtcNow);
                    }

                    // Handle past scheduled meetings
                    var pastScheduledMeetings = await unitOfWork.Meetings.GetPastScheduledMeetingsAsync(
                        DateTime.UtcNow,
                        BatchSize,
                        stoppingToken);

                    foreach (var meeting in pastScheduledMeetings)
                    {
                        meeting.Status = MeetingStatus.Cancelled;
                        _logger.LogInformation(
                            "Cancelled past scheduled meeting {MeetingId} that never started",
                            meeting.Id);
                    }

                    if (pastScheduledMeetings.Any())
                    {
                        await unitOfWork.CompleteAsync();
                        _logger.LogInformation(
                            "Cancelled {Count} past scheduled meetings at {Time} UTC", 
                            pastScheduledMeetings.Count,
                            DateTime.UtcNow);
                    }
                }
                catch (OperationCanceledException)
                {
                    _logger.LogInformation("{ServiceName} stopping", nameof(MeetingStatusWorker));
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in {ServiceName}", nameof(MeetingStatusWorker));
                }

                await Task.Delay(_processInterval, stoppingToken);
            }
        }
    }
} 