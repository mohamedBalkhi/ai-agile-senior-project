using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Senior.AgileAI.BaseMgt.Infrastructure.Repositories;
using Senior.AgileAI.BaseMgt.Infrastructure.Services;

namespace Senior.AgileAI.BaseMgt.Infrastructure;

public static class InfrastructureDependencyContainer
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {

        // Add UnitOfWork
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Add any other infrastructure services here
        services.AddScoped<IAuthService, AuthService>();
        

        

        return services;
    }
}