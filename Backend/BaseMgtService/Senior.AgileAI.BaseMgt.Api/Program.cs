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

var builder = WebApplication.CreateBuilder(args);

// Add this near the top of the file, after var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();

// Add services to the container.
builder.Services.AddPostgreSqlAppDbContext(builder.Configuration); // ? PostgreSql
builder.Services.AddHttpContextAccessor();
builder.Services.AddInfrastructureServices(); // ? DI Of Infrastrcture.
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

// Add RabbitMQ configuration
builder.Services.Configure<RabbitMQOptions>(builder.Configuration.GetSection("RabbitMQ"));

// Add this after other service configurations
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();


app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        context.Response.StatusCode = 500;
        context.Response.ContentType = "text/plain";
        var errorFeature = context.Features.Get<IExceptionHandlerFeature>();
        if (errorFeature != null)
        {
            var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
            logger.LogError($"Unhandled exception: {errorFeature.Error}");
            await context.Response.WriteAsync("An unhandled exception occurred.");
        }
    });
});

app.UseStatusCodePages();

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

app.Run();
