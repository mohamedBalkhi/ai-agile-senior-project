using System.Net.Sockets;
using Microsoft.Extensions.Logging;
using Polly;
using Polly.CircuitBreaker;
using Polly.Retry;
using Polly.Timeout;
using Senior.AgileAI.BaseMgt.Application.Exceptions;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Resilience;
public interface IResiliencePolicy<T>
{
    Task<TResult> ExecuteAsync<TResult>(Func<Task<TResult>> action);
    Task ExecuteAsync(Func<Task> action);
}

public class ResiliencePolicyOptions
{
    public int MaxRetries { get; init; } = 3;
    public double CircuitBreakerFailureThreshold { get; init; } = 0.5;
    public TimeSpan CircuitBreakerSamplingDuration { get; init; } = TimeSpan.FromMinutes(2);
    public TimeSpan CircuitBreakerDurationOfBreak { get; init; } = TimeSpan.FromSeconds(30);
    public TimeSpan TimeoutDuration { get; init; } = TimeSpan.FromSeconds(30);
}

public class ResiliencePolicy<T> : IResiliencePolicy<T>
{
    private readonly IAsyncPolicy _policy;
    private readonly ILogger _logger;

    public ResiliencePolicy(ILogger<T> logger, ResiliencePolicyOptions options)
    {
        _logger = logger;
        
        var retry = Policy
            .Handle<HttpRequestException>()
            .Or<TimeoutRejectedException>()
            .Or<SocketException>()
            .Or<AIProcessingException>()
            .WaitAndRetryAsync(
                options.MaxRetries,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                (exception, timeSpan, retryCount, context) =>
                {
                    _logger.LogWarning(
                        exception,
                        "[{Service}] Retry {RetryCount} after {Delay}ms",
                        typeof(T).Name,
                        retryCount,
                        timeSpan.TotalMilliseconds);
                });

        var circuitBreaker = Policy
            .Handle<HttpRequestException>()
            .Or<TimeoutRejectedException>()
            .Or<SocketException>()
            .Or<AIProcessingException>()
            .AdvancedCircuitBreakerAsync(
                options.CircuitBreakerFailureThreshold,
                options.CircuitBreakerSamplingDuration,
                10,
                options.CircuitBreakerDurationOfBreak,
                (ex, duration) =>
                {
                    _logger.LogError(
                        ex,
                        "[{Service}] Circuit breaker opened for {Duration}ms",
                        typeof(T).Name,
                        duration.TotalMilliseconds);
                },
                () =>
                {
                    _logger.LogInformation(
                        "[{Service}] Circuit breaker closed",
                        typeof(T).Name);
                },
                () =>
                {
                    _logger.LogWarning(
                        "[{Service}] Circuit breaker half-open",
                        typeof(T).Name);
                });

        var timeout = Policy.TimeoutAsync(
            options.TimeoutDuration,
            (context, timeSpan, task) =>
            {
                _logger.LogWarning(
                    "[{Service}] Timeout after {Timeout}ms",
                    typeof(T).Name,
                    timeSpan.TotalMilliseconds);
                return Task.CompletedTask;
            });

        _policy = Policy.WrapAsync(timeout, retry, circuitBreaker);
    }

    public async Task<TResult> ExecuteAsync<TResult>(Func<Task<TResult>> action)
    {
        return await _policy.ExecuteAsync(action);
    }

    public async Task ExecuteAsync(Func<Task> action)
    {
        await _policy.ExecuteAsync(action);
    }
} 