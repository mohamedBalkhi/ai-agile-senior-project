using System.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Infrastructure.Options;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Constants;
using Polly.Retry;
using Polly.CircuitBreaker;
using Senior.AgileAI.BaseMgt.Infrastructure.Resilience;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class RabbitMQService : IRabbitMQService, IDisposable
{
    private readonly RabbitMQOptions _options;
    private readonly IConnection _connection;
    private readonly IModel _channel;
    private readonly ILogger<RabbitMQService> _logger;
    private readonly IResiliencePolicy<RabbitMQService> _resiliencePolicy;

    public RabbitMQService(
        IOptions<RabbitMQOptions> options,
        ILogger<RabbitMQService> logger,
        IResiliencePolicy<RabbitMQService> resiliencePolicy)
    {
        _options = options.Value;
        _logger = logger;
        _resiliencePolicy = resiliencePolicy;
        

        
        try
        {
            var factory = new ConnectionFactory() 
            { 
                HostName = _options.HostName,
                UserName = _options.UserName,
                Password = _options.Password,
                VirtualHost = _options.VirtualHost
            };
            
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            // Declare all configured queues
            foreach (var queue in _options.Queues)
            {
                _logger.LogInformation($"Declaring queue: {queue.Value}");
                _channel.QueueDeclare(
                    queue: queue.Value,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize RabbitMQ connection");
            throw;
        }
    }

    public async Task PublishNotificationAsync(NotificationMessage message)
    {
        await PublishMessageAsync(QueueNames.Notifications, message);
    }

    public async Task PublishMessageAsync<T>(string queueName, T message) where T : class
    {
        await _resiliencePolicy.ExecuteAsync(async () =>
        {
            if (!_options.Queues.TryGetValue(queueName, out var actualQueueName))
            {
                throw new ArgumentException($"Queue {queueName} is not configured.", nameof(queueName));
            }

            try
            {
                string json = JsonConvert.SerializeObject(message);
                var body = Encoding.UTF8.GetBytes(json);

                var properties = _channel.CreateBasicProperties();
                properties.Persistent = true;

                _logger.LogInformation($"Publishing message to queue '{actualQueueName}': {json}");
                _channel.BasicPublish(exchange: "",
                                    routingKey: actualQueueName,
                                    basicProperties: properties,
                                    body: body);

                _logger.LogInformation($"Message successfully published to queue '{actualQueueName}'");
                await Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error publishing message to queue '{actualQueueName}'");
                throw;
            }
        });
    }

    public void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
    }
}
