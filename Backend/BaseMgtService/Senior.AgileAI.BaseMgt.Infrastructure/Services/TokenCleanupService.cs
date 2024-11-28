using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class TokenCleanupService : BackgroundService
{
    private readonly ILogger<TokenCleanupService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly TimeSpan _cleanupInterval = TimeSpan.FromDays(1); // Run daily

    public TokenCleanupService(
        ILogger<TokenCleanupService> logger,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CleanupTokens(stoppingToken);
                await Task.Delay(_cleanupInterval, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while cleaning up tokens");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Wait before retrying
            }
        }
    }

    private async Task CleanupTokens(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting token cleanup process");

        using var scope = _serviceProvider.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

        try
        {
            var tokensToClean = await unitOfWork.NotificationTokens.GetTokensToClean(stoppingToken);
            
            foreach (var token in tokensToClean)
            {
                await unitOfWork.NotificationTokens.DeleteToken(token.Token, token.DeviceId, stoppingToken);
            }

            await unitOfWork.CompleteAsync();
            
            _logger.LogInformation("Cleaned up {Count} tokens", tokensToClean.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token cleanup");
            throw;
        }
    }
} 