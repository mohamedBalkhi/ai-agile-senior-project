using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddPostgreSqlAppDbContext(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<PostgreSqlAppDbContext>((serviceProvider, options) =>
        {
            options.UseNpgsql(configuration.GetConnectionString("PostgreSqlConnection"),
                b => b.MigrationsAssembly("Senior.AgileAI.BaseMgt.Api"));
        });

        return services;
    }
    
    
}
