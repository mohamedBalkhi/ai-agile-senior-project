using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

public class OnlineMeetingWorker : BackgroundService
{
    private readonly ILogger<OnlineMeetingWorker> _logger;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(1);

    public OnlineMeetingWorker(
        ILogger<OnlineMeetingWorker> logger,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
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

    private async Task CheckOnlineMeetings(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var onlineMeetingService = scope.ServiceProvider.GetRequiredService<IOnlineMeetingService>();

        // Get all active online meetings
        var activeMeetings = await unitOfWork.Meetings.GetActiveMeetingsAsync(
            type: MeetingType.Online,
            cancellationToken: cancellationToken
        );

        foreach (var meeting in activeMeetings)
        {
            try
            {
                if (string.IsNullOrEmpty(meeting.LiveKitRoomName))
                {
                    continue;
                }

                // Check if room still exists
                var room = await onlineMeetingService.GetRoomAsync(meeting.LiveKitRoomName, cancellationToken);
                
                // If room doesn't exist (terminated due to inactivity)
                if (room == null)
                {
                    _logger.LogInformation("Room {RoomName} terminated, marking meeting as cancelled", meeting.LiveKitRoomName);
                    var status = meeting.Status;
                    meeting.Complete();
                    if (status != MeetingStatus.InProgress) {
                        meeting.Status = MeetingStatus.Cancelled;
                    }
               
                    
                    await unitOfWork.CompleteAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking room {RoomName}", meeting.LiveKitRoomName);
            }
        }
    }
} 