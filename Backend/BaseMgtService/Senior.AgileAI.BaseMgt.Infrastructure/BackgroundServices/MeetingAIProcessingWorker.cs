using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Threading;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

public class MeetingAIProcessingWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<MeetingAIProcessingWorker> _logger;
    private readonly TimeSpan _initialInterval = TimeSpan.FromSeconds(3);
    private readonly TimeSpan _maxInterval = TimeSpan.FromSeconds(30);
    private readonly Dictionary<Guid, (DateTime StartTime, int RetryCount)> _processingJobs = new();
    private const int BatchSize = 20;
    private const int MaxRetries = 6;
    private readonly SemaphoreSlim _processingThrottle = new(5);

    public MeetingAIProcessingWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<MeetingAIProcessingWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("{ServiceName} starting", nameof(MeetingAIProcessingWorker));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessMeetingsAsync(stoppingToken);
                
                // Calculate next delay based on active jobs
                var nextDelay = _processingJobs.Any() 
                    ? _initialInterval 
                    : _maxInterval;
                
                await Task.Delay(nextDelay, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while processing meetings");
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            }
        }
    }

    private async Task ProcessMeetingsAsync(CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var aiService = scope.ServiceProvider.GetRequiredService<IAIProcessingService>();

        // Process both new and pending meetings concurrently
        await Task.WhenAll(
            InitiateNewProcessingAsync(unitOfWork, aiService, stoppingToken),
            UpdatePendingProcessingAsync(unitOfWork, aiService, stoppingToken)
        );
    }

    private async Task InitiateNewProcessingAsync(
        IUnitOfWork unitOfWork,
        IAIProcessingService aiService,
        CancellationToken stoppingToken)
    {
        var meetings = await unitOfWork.Meetings
            .GetMeetingsForAIProcessingAsync(BatchSize, stoppingToken);

        var tasks = meetings.Select(async meeting =>
        {
            await _processingThrottle.WaitAsync(stoppingToken);
            try
            {
                if (!meeting.CanProcessAudio())
                {
                    return;
                }

                var token = await aiService.SubmitAudioForProcessingAsync(
                    meeting.AudioUrl!,
                    stoppingToken);

                meeting.InitiateAIProcessing(token);
                _processingJobs.Add(meeting.Id, (DateTime.UtcNow, 0));

                await unitOfWork.CompleteAsync();

                _logger.LogInformation(
                    "Initiated AI processing for meeting {Id}",
                    meeting.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to initiate AI processing for meeting {Id}",
                    meeting.Id);
            }
            finally
            {
                _processingThrottle.Release();
            }
        });

        await Task.WhenAll(tasks);
    }

    private async Task UpdatePendingProcessingAsync(
        IUnitOfWork unitOfWork,
        IAIProcessingService aiService,
        CancellationToken stoppingToken)
    {
        var meetings = await unitOfWork.Meetings
            .GetMeetingsWithPendingAIProcessingAsync(BatchSize, stoppingToken);

        var tasks = meetings.Select(async meeting =>
        {
            await _processingThrottle.WaitAsync(stoppingToken);
            try
            {
                if (!_processingJobs.TryGetValue(meeting.Id, out var jobInfo))
                {
                    _processingJobs[meeting.Id] = (DateTime.UtcNow, 0);
                    return;
                }

                if (meeting.AIProcessingToken is null)
                {
                    return;
                }

                var (isDone, status) = await aiService.GetProcessingStatusAsync(
                    meeting.AIProcessingToken,
                    stoppingToken);

                if (!isDone)
                {
                    var retryCount = jobInfo.RetryCount + 1;
                    var delay = CalculateDelay(retryCount);
                    _processingJobs[meeting.Id] = (jobInfo.StartTime, retryCount);
                    meeting.UpdateAIProcessingStatus(AIProcessingStatus.Processing);
                    await Task.Delay(delay, stoppingToken);
                    return;
                }

                var report = await aiService.GetProcessingReportAsync(
                    meeting.AIProcessingToken,
                    stoppingToken);

                meeting.UpdateAIProcessingStatus(AIProcessingStatus.Completed);
                meeting.SetAIReport(report);
                _processingJobs.Remove(meeting.Id);

                await unitOfWork.CompleteAsync();

                _logger.LogInformation(
                    "Completed AI processing for meeting {Id} after {Duration}",
                    meeting.Id,
                    DateTime.UtcNow - jobInfo.StartTime);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to update AI processing status for meeting {Id}",
                    meeting.Id);

                meeting.UpdateAIProcessingStatus(AIProcessingStatus.Failed);
                await unitOfWork.CompleteAsync();
            }
            finally
            {
                _processingThrottle.Release();
            }
        });

        await Task.WhenAll(tasks);
    }

    private TimeSpan CalculateDelay(int retryCount)
    {
        var delay = _initialInterval * Math.Pow(1.5, retryCount);
        return delay > _maxInterval ? _maxInterval : delay;
    }
}
