using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Repositories;
using Senior.AgileAI.BaseMgt.Infrastructure.Services;
using Senior.AgileAI.BaseMgt.Infrastructure.Utils;

namespace Senior.AgileAI.BaseMgt.Infrastructure;

public static class InfrastructureDependencyContainer
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        // Add UnitOfWork
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Add any other infrastructure services here
        services.AddScoped<IAuthService, AuthService>();

        // Add password hasher
        services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();

        // Add RabbitMQ service
        services.AddSingleton<IRabbitMQService, RabbitMQService>();

        // Add Token Resolver
        services.AddScoped<ITokenResolver, TokenResolver>();

        services.AddScoped<IFileParserStrategyFactory, FileParserStrategyFactory>();

        return services;
    }
}
