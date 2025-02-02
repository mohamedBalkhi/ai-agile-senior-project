using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Domain.Enums;

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
        _logger.LogInformation("Starting {ServiceName}", nameof(MeetingAIProcessingWorker));

        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
                var aiService = scope.ServiceProvider.GetRequiredService<IAIProcessingService>();

                try
                {
                    // Cleanup stale jobs before processing
                    CleanupStaleJobs();

                    // Process new and pending meetings
                    await InitiateNewProcessingAsync(unitOfWork, aiService, stoppingToken);
                    await UpdatePendingProcessingAsync(unitOfWork, aiService, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Error during processing loop");
                }

                await Task.Delay(_initialInterval, stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Processing loop stopped");
        }
    }

    private async Task ProcessMeetingsAsync(CancellationToken stoppingToken)
    {
        try
        {
            // Process new meetings first
            using (var scope = _scopeFactory.CreateScope())
            {
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
                var aiService = scope.ServiceProvider.GetRequiredService<IAIProcessingService>();
                await InitiateNewProcessingAsync(unitOfWork, aiService, stoppingToken);
            }

            // Then process pending meetings in a separate scope
            using (var scope = _scopeFactory.CreateScope())
            {
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
                var aiService = scope.ServiceProvider.GetRequiredService<IAIProcessingService>();
                await UpdatePendingProcessingAsync(unitOfWork, aiService, stoppingToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred while processing meetings");
            throw;
        }
    }

    private async Task InitiateNewProcessingAsync(
        IUnitOfWork unitOfWork,
        IAIProcessingService aiService,
        CancellationToken stoppingToken)
    {
        var meetings = await unitOfWork.Meetings
            .GetMeetingsForAIProcessingAsync(BatchSize, stoppingToken);

        foreach (var meeting in meetings)
        {
            await _processingThrottle.WaitAsync(stoppingToken);
            try
            {
                if (!meeting.CanProcessAudio())
                {
                    _logger.LogDebug(
                        "Meeting {Id} not ready for AI processing",
                        meeting.Id);
                    continue;
                }

                _logger.LogInformation(
                    "Starting AI processing for meeting {Id}. Language: {Language}, AudioUrl: {Url}",
                    meeting.Id,
                    meeting.Language,
                    meeting.AudioUrl);

                var token = await aiService.SubmitAudioForProcessingAsync(
                    meeting.AudioUrl!,
                    meeting.Language == MeetingLanguage.English ? "en" : "ar",
                    stoppingToken);

                meeting.InitiateAIProcessing(token);
                _processingJobs.Add(meeting.Id, (DateTime.UtcNow, 0));

                await unitOfWork.CompleteAsync();

                _logger.LogInformation(
                    "Successfully initiated AI processing for meeting {Id}. Token: {Token}",
                    meeting.Id,
                    token);
            }
            catch (AIProcessingException ex)
            {
                _logger.LogError(
                    "AI service error for meeting {Id}: {Error}",
                    meeting.Id,
                    ex.Message);

                // If circuit breaker is open, pause processing
                if (ex.Message.Contains("Circuit breaker"))
                {
                    _logger.LogWarning(
                        "Circuit breaker open - pausing processing for 30s");
                    await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Unexpected error initiating AI processing for meeting {Id}",
                    meeting.Id);
            }
            finally
            {
                _processingThrottle.Release();
            }
        }
    }

    private async Task UpdatePendingProcessingAsync(
        IUnitOfWork unitOfWork,
        IAIProcessingService aiService,
        CancellationToken stoppingToken)
    {
        var meetings = await unitOfWork.Meetings
            .GetMeetingsWithPendingAIProcessingAsync(BatchSize, stoppingToken);

        foreach (var meeting in meetings)
        {
            await _processingThrottle.WaitAsync(stoppingToken);
            try
            {
                if (meeting.AIProcessingToken is null)
                {
                    _logger.LogWarning(
                        "Meeting {Id} has no processing token",
                        meeting.Id);
                    continue;
                }

                var (isDone, status) = await aiService.GetProcessingStatusAsync(
                    meeting.AIProcessingToken,
                    stoppingToken);

                if (!isDone)
                {
                    _logger.LogInformation(
                        "Meeting {Id} still processing. Status: {Status}",
                        meeting.Id,
                        status);
                        
                    meeting.UpdateAIProcessingStatus(AIProcessingStatus.Processing);
                    await unitOfWork.CompleteAsync();
                    continue;
                }

                _logger.LogInformation(
                    "Fetching AI processing report for meeting {Id}",
                    meeting.Id);

                var report = await aiService.GetProcessingReportAsync(
                    meeting.AIProcessingToken,
                    stoppingToken);

                meeting.UpdateAIProcessingStatus(AIProcessingStatus.Completed);
                meeting.SetAIReport(report);
                await unitOfWork.CompleteAsync();

                _logger.LogInformation(
                    "Completed AI processing for meeting {Id}",
                    meeting.Id);
            }
            catch (AIProcessingException ex) when (ex.Message.Contains("Circuit breaker"))
            {
                _logger.LogWarning(
                    "Circuit breaker open for meeting {Id} - will retry later",
                    meeting.Id);
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error updating AI processing status for meeting {Id}",
                    meeting.Id);
            }
            finally
            {
                _processingThrottle.Release();
            }
        }
    }

    private TimeSpan CalculateDelay(int retryCount)
    {
        var delay = _initialInterval * Math.Pow(1.5, retryCount);
        return delay > _maxInterval ? _maxInterval : delay;
    }

    private void CleanupStaleJobs()
    {
        var staleTimeout = TimeSpan.FromHours(1);
        var staleJobs = _processingJobs
            .Where(j => DateTime.UtcNow - j.Value.StartTime > staleTimeout)
            .ToList();

        foreach (var job in staleJobs)
        {
            _logger.LogWarning(
                "Removing stale job for meeting {Id}. Started: {Start}",
                job.Key,
                job.Value.StartTime);
            _processingJobs.Remove(job.Key);
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Stopping {ServiceName}", nameof(MeetingAIProcessingWorker));
        
        // Wait for active jobs to complete (with timeout)
        var timeout = TimeSpan.FromSeconds(30);
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(timeout);
        
        try 
        {
            while (_processingJobs.Any())
            {
                await Task.Delay(1000, cts.Token);
                _logger.LogInformation(
                    "Waiting for {Count} jobs to complete",
                    _processingJobs.Count);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning(
                "Shutdown timeout reached with {Count} jobs remaining",
                _processingJobs.Count);
        }
        
        _processingThrottle.Dispose();
        await base.StopAsync(cancellationToken);
    }
}
