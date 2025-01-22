using Amazon.S3;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;
using Senior.AgileAI.BaseMgt.Infrastructure.Repositories;
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

        // Register OnlineMeetingService
        services.AddHttpClient<IOnlineMeetingService, OnlineMeetingService>();

        // Register AIProcessingService
        services.AddHttpClient<IAIProcessingService, AIProcessingService>();

        return services;
    }
}
