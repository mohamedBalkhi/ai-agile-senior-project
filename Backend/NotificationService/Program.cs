using NotificationService.MessageHandlers;
using NotificationService.Services.Interfaces;
using NotificationService.Services.Implementations;
using NotificationService.Options;
using RabbitMQ.Client;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

// Add configuration sources
builder.Configuration
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Register notification services
builder.Services.AddScoped<IEmailNotificationService, EmailNotificationService>();
builder.Services.AddScoped<IFirebaseNotificationService, FirebaseNotificationService>();
builder.Services.AddScoped<INotificationHandler, NotificationHandler>();

// Add RabbitMQ configuration
builder.Services.Configure<RabbitMQOptions>(options =>
{
    var section = builder.Configuration.GetSection("RabbitMQ");
    options.HostName = section["HostName"] ?? "agilemeets-rabbitmq.internal";
    options.UserName = section["UserName"] ?? "guest";
    options.Password = section["Password"] ?? "guest";
    options.QueueName = section["QueueName"] ?? "notifications_queue";
    options.VirtualHost = section["VirtualHost"] ?? "/";
});

// Add health checks
builder.Services.AddHealthChecks();

builder.WebHost.UseUrls("http://*:8081");

// Register hosted service
builder.Services.AddHostedService<RabbitMQListener>();

var app = builder.Build();

// Add graceful shutdown handling
var lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>();
lifetime.ApplicationStopping.Register(() =>
{
    app.Logger.LogInformation("Application is shutting down...");
    // Allow time for current operations to complete
    Thread.Sleep(TimeSpan.FromSeconds(5));
});

// Configure RabbitMQ delay exchange **and** declare the queue before binding
using (var scope = app.Services.CreateScope())
{
    var rabbitMQOptions = scope.ServiceProvider.GetRequiredService<IOptions<RabbitMQOptions>>().Value;
    var factory = new ConnectionFactory
    {
        HostName = rabbitMQOptions.HostName,
        UserName = rabbitMQOptions.UserName,
        Password = rabbitMQOptions.Password,
        VirtualHost = rabbitMQOptions.VirtualHost
    };

    using var connection = factory.CreateConnection();
    using var channel = connection.CreateModel();
    
    // 1) Declare the queue
    channel.QueueDeclare(
        queue: rabbitMQOptions.QueueName,
        durable: true,
        exclusive: false,
        autoDelete: false,
        arguments: null);

    // 2) Declare the delay exchange
    channel.ExchangeDeclare(
        exchange: rabbitMQOptions.DelayExchange,
        type: "x-delayed-message",
        durable: true,
        autoDelete: false,
        arguments: new Dictionary<string, object>
        {
            { "x-delayed-type", "direct" }
        });

    // 3) Bind the queue to the delay exchange
    channel.QueueBind(
        queue: rabbitMQOptions.QueueName,
        exchange: rabbitMQOptions.DelayExchange,
        routingKey: rabbitMQOptions.QueueName);
}

// Re-enable health checks
app.MapHealthChecks("/health");

app.Run();

app.Lifetime.ApplicationStarted.Register(() =>
{
    app.Logger.LogInformation("Notification service has started listening for messages...");
});
