using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class TokenCleanupWorker : BackgroundService
{
    private readonly ILogger<TokenCleanupWorker> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly TimeSpan _cleanupInterval = TimeSpan.FromDays(1);
    private readonly SemaphoreSlim _cleanupLock = new(1);

    public TokenCleanupWorker(
        ILogger<TokenCleanupWorker> logger,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting {ServiceName}", nameof(TokenCleanupWorker));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (await _cleanupLock.WaitAsync(TimeSpan.FromSeconds(5), stoppingToken))
                {
                    try
                    {
                        await CleanupTokens(stoppingToken);
                    }
                    finally
                    {
                        _cleanupLock.Release();
                    }
                }

                await Task.Delay(_cleanupInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("Token cleanup operation cancelled");
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while cleaning up tokens");
                
                // Wait a shorter time before retrying on error
                try
                {
                    await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }
        }

        _logger.LogInformation("Stopping {ServiceName}", nameof(TokenCleanupWorker));
    }

    private async Task CleanupTokens(CancellationToken stoppingToken)
    {
        var operationId = Guid.NewGuid().ToString()[..8];
        _logger.LogInformation("[{OperationId}] Starting token cleanup process", operationId);

        using var scope = _serviceProvider.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

        try
        {
            var tokensToClean = await unitOfWork.NotificationTokens
                .GetTokensToClean(stoppingToken);

            if (!tokensToClean.Any())
            {
                _logger.LogInformation("[{OperationId}] No tokens to clean", operationId);
                return;
            }

            var batchSize = 100;
            var processedCount = 0;

            foreach (var batch in tokensToClean.Chunk(batchSize))
            {
                if (stoppingToken.IsCancellationRequested)
                {
                    _logger.LogInformation(
                        "[{OperationId}] Cleanup cancelled after processing {Count} tokens",
                        operationId, processedCount);
                    break;
                }

                foreach (var token in batch)
                {
                    await unitOfWork.NotificationTokens
                        .DeleteToken(token.Token, token.DeviceId, stoppingToken);
                    processedCount++;
                }

                await unitOfWork.CompleteAsync();
                
                _logger.LogInformation(
                    "[{OperationId}] Processed batch of {BatchSize} tokens. Total: {Total}",
                    operationId, batch.Length, processedCount);
            }

            _logger.LogInformation(
                "[{OperationId}] Completed cleanup. Total tokens cleaned: {Count}",
                operationId, processedCount);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(
                ex,
                "[{OperationId}] Error during token cleanup",
                operationId);
            throw;
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Stopping {ServiceName}", nameof(TokenCleanupWorker));
        
        _cleanupLock.Dispose();
        await base.StopAsync(cancellationToken);
    }
} 