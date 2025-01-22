using Senior.AgileAI.BaseMgt.Infrastructure.Extensions;
using Senior.AgileAI.BaseMgt.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Senior.AgileAI.BaseMgt.Infrastructure.Options;
using Senior.AgileAI.BaseMgt.Application;
using Senior.AgileAI.BaseMgt.Application.Common.Constants;
using Microsoft.OpenApi.Models;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Infrastructure.Services;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Api.Middleware;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices;

var builder = WebApplication.CreateBuilder(args);

// Add HTTP logging configuration
builder.Services.AddHttpLogging(logging =>
{
    logging.LoggingFields = Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.All;
    logging.RequestHeaders.Add("Authorization");
    logging.ResponseHeaders.Add("WWW-Authenticate");
});

// Add this near the top of the file, after var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();

// Add this after builder.Configuration.AddEnvironmentVariables();
var dbUrl = builder.Configuration["DATABASE_URL"];
if (!string.IsNullOrEmpty(dbUrl))
{
    // Parse DATABASE_URL for Fly.io
    var uri = new Uri(dbUrl);
    var userInfo = uri.UserInfo.Split(':');
    var host = uri.Host;
    var port = uri.Port;
    var database = uri.AbsolutePath.TrimStart('/');
    
    builder.Configuration["ConnectionStrings:PostgreSqlConnection"] = 
        $"Host={host};Database={database};Username={userInfo[0]};Password={userInfo[1]};Port={port};SSL Mode=Disable";
}

// Add services to the container.
builder.Services.AddPostgreSqlAppDbContext(builder.Configuration); // ? PostgreSql
builder.Services.AddHttpContextAccessor();
builder.Services.AddInfrastructureServices(builder.Configuration); // ? DI Of Infrastrcture.
builder.Services.AddApplicationServices(); // ? DI Of Application.
builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Base Management API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: 'Authorization: Bearer {token}'",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new List<string>()
        }
    });
});

// Add authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var jwtKey = builder.Configuration["Jwt:Key"] ?? 
            throw new InvalidOperationException("JWT Key is not configured");
        var keyBytes = Convert.FromBase64String(jwtKey);
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

// Add authorization
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(PolicyConstants.AdminPolicy, policy =>
        policy.RequireClaim(PolicyConstants.IsAdminClaim, "True"));
});

builder.WebHost.UseUrls("http://*:8080");

// Replace the existing RabbitMQ configuration
builder.Services.Configure<RabbitMQOptions>(options =>
{
    var section = builder.Configuration.GetSection("RabbitMQ");
    options.HostName = section["HostName"] ?? "agilemeets-rabbitmq.internal";
    options.UserName = section["UserName"] ?? "guest";
    options.Password = section["Password"] ?? "guest";
    options.VirtualHost = section["VirtualHost"] ?? "/";  // Add this
    
    options.Queues = new Dictionary<string, string>
    {
        { "Notifications", "notifications_queue" }
    };
});

// Add this after other service configurations
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

// Add this with the other service configurations
builder.Services.AddHealthChecks()
    .AddDbContextCheck<PostgreSqlAppDbContext>();

// Add this to your service registration
builder.Services.AddHostedService<CalendarSubscriptionCleanupWorker>();
builder.Services.AddHostedService<OnlineMeetingWorker>();

var app = builder.Build();

// Add HTTP logging middleware
app.UseHttpLogging();

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();
app.UseGlobalExceptionHandler();

// Allow all CORS
app.UseCors(builder =>
{
    builder.AllowAnyOrigin()
           .AllowAnyMethod()
           .AllowAnyHeader();
});

app.MapControllers();

// Apply migrations and seed data at startup
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<PostgreSqlAppDbContext>();
        if (context.Database.GetPendingMigrations().Any())
        {
            Console.WriteLine("Applying migrations...");
            context.Database.Migrate();
            Console.WriteLine("Migrations applied successfully.");
        }
        else
        {
            Console.WriteLine("No pending migrations.");
        }

        // Initialize the database with seed data
        DbInitializer.Initialize(services);
        Console.WriteLine("Seed data applied successfully.");
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while migrating or seeding the database.");
    }
}

// Add this before app.Run()
app.MapHealthChecks("/health");

app.Run();
