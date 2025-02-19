using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using System.Threading;
using System.Threading.Tasks;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

public class OnlineMeetingWorker : BackgroundService
{
    private readonly ILogger<OnlineMeetingWorker> _logger;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(1);
    private readonly SemaphoreSlim _processingThrottle = new(5);

    public OnlineMeetingWorker(
        ILogger<OnlineMeetingWorker> logger,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting {ServiceName}", nameof(OnlineMeetingWorker));

        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckOnlineMeetings(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while checking online meetings");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Processing loop stopped");
        }
    }

    private async Task CheckOnlineMeetings(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var onlineMeetingService = scope.ServiceProvider.GetRequiredService<IOnlineMeetingService>();

        var activeMeetings = await unitOfWork.Meetings.GetActiveMeetingsAsync(
            type: MeetingType.Online,
            cancellationToken: cancellationToken
        );

        foreach (var meeting in activeMeetings)
        {
            await _processingThrottle.WaitAsync(cancellationToken);
            try
            {
                var operationId = Guid.NewGuid().ToString()[..8];

                if (string.IsNullOrEmpty(meeting.LiveKitRoomName))
                {
                    _logger.LogDebug(
                        "[{OperationId}] Meeting {Id} has no LiveKit room name",
                        operationId, meeting.Id);
                    continue;
                }

                _logger.LogDebug(
                    "[{OperationId}] Checking room status for meeting {Id}, Room: {Room}",
                    operationId, meeting.Id, meeting.LiveKitRoomName);

                // OnlineMeetingService already handles retries via Polly
                var room = await onlineMeetingService.GetRoomAsync(
                    meeting.LiveKitRoomName, 
                    cancellationToken);
                
                if (room == null)
                {
                    _logger.LogInformation(
                        "[{OperationId}] Room {RoomName} terminated, updating meeting {Id}",
                        operationId, meeting.LiveKitRoomName, meeting.Id);

                    var status = meeting.Status;
                    meeting.Complete();
                    
                    // Only mark as cancelled if it wasn't in progress
                    if (status != MeetingStatus.InProgress)
                    {
                        meeting.Status = MeetingStatus.Cancelled;
                    }
                    unitOfWork.Meetings.Update(meeting);

                    
                    await unitOfWork.CompleteAsync();

                    _logger.LogInformation(
                        "[{OperationId}] Meeting {Id} updated. Final status: {Status}",
                        operationId, meeting.Id, meeting.Status);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error checking room for meeting {Id}",
                    meeting.Id);
            }
            finally
            {
                _processingThrottle.Release();
            }
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Stopping {ServiceName}", nameof(OnlineMeetingWorker));
        
        _processingThrottle.Dispose();
        await base.StopAsync(cancellationToken);
    }
} 