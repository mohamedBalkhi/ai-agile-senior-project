
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;


namespace Senior.AgileAI.BaseMgt.Infrastructure;

public static class InfrastructureDependencyContainer
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {

        // Add MediaTr
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));
    
        return services;
    }
}