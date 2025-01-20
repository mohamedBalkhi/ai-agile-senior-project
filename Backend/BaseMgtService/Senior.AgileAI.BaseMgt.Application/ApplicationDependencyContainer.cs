using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Behaviors;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using MediatR;
using Senior.AgileAI.BaseMgt.Application.Services;

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
        services.AddScoped<IRecurringMeetingService, RecurringMeetingService>();

        // Add Pipeline Behaviors
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));

        return services;
    }
}
