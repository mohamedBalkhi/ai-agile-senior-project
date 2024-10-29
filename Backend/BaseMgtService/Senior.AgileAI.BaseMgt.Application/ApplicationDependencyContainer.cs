using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Behaviors;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application;

public static class ApplicationDependencyContainer
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // Add Validators
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

        // Add Authorization Helper
        services.AddScoped<IProjectAuthorizationHelper, ProjectAuthorizationHelper>();

        // Add Validation Behavior
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));

        return services;
    }
}
