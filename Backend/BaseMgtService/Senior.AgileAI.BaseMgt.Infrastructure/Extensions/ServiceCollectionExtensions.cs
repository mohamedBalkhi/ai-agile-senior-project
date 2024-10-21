using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddPostgreSqlAppDbContext(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<PostgreSqlAppDbContext>(options =>
        {
            var connectionString = configuration.GetConnectionString("PostgreSqlConnection");
            Console.WriteLine($"Configuring DbContext with connection string: {connectionString}");
            options.UseNpgsql(connectionString, b => b.MigrationsAssembly("Senior.AgileAI.BaseMgt.Api"));
        });

        return services;
    }
    
    
}
