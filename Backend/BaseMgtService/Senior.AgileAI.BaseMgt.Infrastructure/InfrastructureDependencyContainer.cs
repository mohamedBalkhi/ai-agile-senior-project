using Amazon.S3;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;
using Senior.AgileAI.BaseMgt.Infrastructure.Repositories;
using Senior.AgileAI.BaseMgt.Infrastructure.Resilience;
using Senior.AgileAI.BaseMgt.Infrastructure.Services;
using Senior.AgileAI.BaseMgt.Infrastructure.Services.FileParsingStrategy;
using Senior.AgileAI.BaseMgt.Infrastructure.Utils;

namespace Senior.AgileAI.BaseMgt.Infrastructure;

public static class InfrastructureDependencyContainer
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        // Add UnitOfWork
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Add any other infrastructure services here
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ITimeZoneService, TimeZoneService>();

        // Add password hasher
        services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();

        // Add RabbitMQ service
        services.AddSingleton<IRabbitMQService, RabbitMQService>();

        // Add Token Resolver
        services.AddScoped<ITokenResolver, TokenResolver>();

        services.AddScoped<IFileParserStrategyFactory, FileParserStrategyFactory>();

        // Add hosted services
        services.AddHostedService<CalendarSubscriptionCleanupWorker>();
        services.AddHostedService<MeetingReminderWorker>();
        services.AddHostedService<MeetingStatusWorker>();
        services.AddHostedService<TokenCleanupWorker>();
        services.AddHostedService<MeetingAIProcessingWorker>();

        // Register AWS S3 client
        services.AddSingleton<IAmazonS3>(sp =>
        {
            var accessKey = configuration["AWS:AccessKey"];
            var secretKey = configuration["AWS:SecretKey"];
            
            var config = new AmazonS3Config
            {
                RegionEndpoint = Amazon.RegionEndpoint.EUCentral1
            };

            return new AmazonS3Client(accessKey, secretKey, config);
        });

        // Register AudioStorageService
        services.AddScoped<IAudioStorageService, AudioStorageService>();
        services.AddScoped<IAIProcessingService, AIProcessingService>();
        services.AddScoped<IAudioTranscodingService, FFmpegAudioTranscodingService>();

        // Register OnlineMeetingService with optimized HTTP client
        services.AddHttpClient<IOnlineMeetingService, OnlineMeetingService>(client =>
        {
            client.DefaultRequestHeaders.ConnectionClose = false;
        })
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(5),
            PooledConnectionIdleTimeout = TimeSpan.FromMinutes(2),
            ConnectTimeout = TimeSpan.FromSeconds(30),
            EnableMultipleHttp2Connections = true
        })
        .SetHandlerLifetime(TimeSpan.FromMinutes(5));

        // Register AIProcessingService
        services.AddHttpClient<IAIProcessingService, AIProcessingService>(client =>
        {
            client.DefaultRequestHeaders.ConnectionClose = false;
        })
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(5),
            PooledConnectionIdleTimeout = TimeSpan.FromMinutes(2),
            ConnectTimeout = TimeSpan.FromSeconds(30),
            EnableMultipleHttp2Connections = true
        })
        .SetHandlerLifetime(TimeSpan.FromMinutes(5));

        // Register service-specific resilience policies
        services.AddSingleton<IResiliencePolicy<OnlineMeetingService>>(sp =>
        {
            var config = configuration.GetSection("Resilience:OnlineMeeting");
            return new ResiliencePolicy<OnlineMeetingService>(
                sp.GetRequiredService<ILogger<OnlineMeetingService>>(),
                new ResiliencePolicyOptions
                {
                    MaxRetries = config.GetValue<int>("MaxRetries"),
                    CircuitBreakerFailureThreshold = config.GetValue<double>("CircuitBreakerFailureThreshold"),
                    CircuitBreakerSamplingDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerSamplingDurationMinutes")),
                    CircuitBreakerDurationOfBreak = TimeSpan.FromSeconds(
                        config.GetValue<int>("CircuitBreakerDurationOfBreakSeconds")),
                    TimeoutDuration = TimeSpan.FromSeconds(
                        config.GetValue<int>("TimeoutSeconds"))
                });
        });

        services.AddSingleton<IResiliencePolicy<AIProcessingService>>(sp =>
        {
            var config = configuration.GetSection("Resilience:AIProcessing");
            return new ResiliencePolicy<AIProcessingService>(
                sp.GetRequiredService<ILogger<AIProcessingService>>(),
                new ResiliencePolicyOptions
                {
                    MaxRetries = config.GetValue<int>("MaxRetries"),
                    CircuitBreakerFailureThreshold = config.GetValue<double>("CircuitBreakerFailureThreshold"),
                    CircuitBreakerSamplingDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerSamplingDurationMinutes")),
                    CircuitBreakerDurationOfBreak = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerDurationOfBreakMinutes")),
                    TimeoutDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("TimeoutMinutes"))
                });
        });

        services.AddSingleton<IResiliencePolicy<RabbitMQService>>(sp =>
        {
            var config = configuration.GetSection("Resilience:RabbitMQ");
            return new ResiliencePolicy<RabbitMQService>(
                sp.GetRequiredService<ILogger<RabbitMQService>>(),
                new ResiliencePolicyOptions
                {
                    MaxRetries = config.GetValue<int>("MaxRetries"),
                    CircuitBreakerFailureThreshold = config.GetValue<double>("CircuitBreakerFailureThreshold"),
                    CircuitBreakerSamplingDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerSamplingDurationMinutes")),
                    CircuitBreakerDurationOfBreak = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerDurationOfBreakMinutes")),
                    TimeoutDuration = TimeSpan.FromSeconds(
                        config.GetValue<int>("TimeoutSeconds"))
                });
        });

        services.AddSingleton<IResiliencePolicy<AudioStorageService>>(sp =>
        {
            var config = configuration.GetSection("Resilience:AudioStorage");
            return new ResiliencePolicy<AudioStorageService>(
                sp.GetRequiredService<ILogger<AudioStorageService>>(),
                new ResiliencePolicyOptions
                {
                    MaxRetries = config.GetValue<int>("MaxRetries"),
                    CircuitBreakerFailureThreshold = config.GetValue<double>("CircuitBreakerFailureThreshold"),
                    CircuitBreakerSamplingDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerSamplingDurationMinutes")),
                    CircuitBreakerDurationOfBreak = TimeSpan.FromMinutes(
                        config.GetValue<int>("CircuitBreakerDurationOfBreakMinutes")),
                    TimeoutDuration = TimeSpan.FromMinutes(
                        config.GetValue<int>("TimeoutMinutes"))
                });
        });

        return services;
    }
}
