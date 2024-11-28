using System.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using NotificationService.Models;
using NotificationService.Services.Interfaces;
using Microsoft.Extensions.Options;
using NotificationService.Options;
using System.Threading;
using System.Threading.Tasks;

namespace NotificationService.MessageHandlers
{
    public class RabbitMQListener : BackgroundService
    {
        private readonly ILogger<RabbitMQListener> _logger;
        private readonly RabbitMQOptions _rabbitMQOptions;
        private readonly IServiceProvider _serviceProvider;
        private IConnection _connection;
        private IModel _channel;
        private string _queueName;
        private const int MaxRetries = 10;
        private const int RetryDelayMs = 5000;

        public RabbitMQListener(
            ILogger<RabbitMQListener> logger,
            IOptions<RabbitMQOptions> rabbitMQOptions,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _rabbitMQOptions = rabbitMQOptions.Value;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                await InitializeRabbitMQAsync();
                
                var consumer = new AsyncEventingBasicConsumer(_channel);
                consumer.Received += ProcessReceivedMessage;

                consumer.ConsumerCancelled += async (sender, args) =>
                {
                    _logger.LogWarning("Consumer was cancelled. Attempting to reconnect...");
                    await InitializeRabbitMQAsync();
                };

                _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

                var consumerTag = _channel.BasicConsume(
                    queue: _queueName,
                    autoAck: false,
                    consumer: consumer);

                _logger.LogInformation($"Started consuming messages from queue: {_queueName} with consumer tag: {consumerTag}");

                while (!stoppingToken.IsCancellationRequested)
                {
                    if (_connection?.IsOpen != true || _channel?.IsOpen != true)
                    {
                        _logger.LogWarning("Connection or channel closed. Attempting to reconnect...");
                        await InitializeRabbitMQAsync();
                    }
                    await Task.Delay(5000, stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("RabbitMQ listener stopping due to cancellation request");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fatal error in RabbitMQ listener. Service will need to be restarted.");
                throw; // Let the host handle the retry
            }
        }

        private async Task InitializeRabbitMQAsync()
        {
            var retryCount = 0;
            while (retryCount < MaxRetries)
            {
                try
                {
                    _logger.LogInformation($"Attempting to connect to RabbitMQ at {_rabbitMQOptions.HostName}");
                    
                    _channel?.Dispose();
                    _connection?.Dispose();

                    var factory = new ConnectionFactory
                    {
                        HostName = _rabbitMQOptions.HostName,
                        UserName = _rabbitMQOptions.UserName,
                        Password = _rabbitMQOptions.Password,
                        VirtualHost = _rabbitMQOptions.VirtualHost,
                        DispatchConsumersAsync = true,
                        AutomaticRecoveryEnabled = true,
                        NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
                        RequestedHeartbeat = TimeSpan.FromSeconds(60)
                    };

                    // CreateConnection and CreateModel can be async operations
                    _connection = await Task.Run(() => factory.CreateConnection());
                    _channel = await Task.Run(() => _connection.CreateModel());
                    _queueName = _rabbitMQOptions.QueueName;

                    _connection.ConnectionShutdown += (sender, args) =>
                    {
                        _logger.LogWarning($"RabbitMQ connection shut down: {args.ReplyText}");
                    };

                    await Task.Run(() => _channel.QueueDeclare(
                        queue: _queueName,
                        durable: true,
                        exclusive: false,
                        autoDelete: false,
                        arguments: null));

                    _logger.LogInformation($"Successfully connected to RabbitMQ and declared queue: {_queueName}");
                    return;
                }
                catch (Exception ex)
                {
                    retryCount++;
                    _logger.LogWarning(ex, $"Failed to connect to RabbitMQ. Attempt {retryCount} of {MaxRetries}");
                    
                    if (retryCount >= MaxRetries) throw;
                    
                    await Task.Delay(RetryDelayMs);
                }
            }
        }

        private async Task ProcessReceivedMessage(object sender, BasicDeliverEventArgs eventArgs)
        {
            var content = Encoding.UTF8.GetString(eventArgs.Body.ToArray());
            _logger.LogInformation($"Received message: {content}");

            try
            {
                using var scope = _serviceProvider.CreateScope();
                var notificationHandler = scope.ServiceProvider.GetRequiredService<INotificationHandler>();
                
                var message = JsonConvert.DeserializeObject<NotificationMessage>(content);
                if (message == null)
                {
                    throw new JsonSerializationException("Failed to deserialize message");
                }

                await notificationHandler.HandleNotificationAsync(message);
                
                _channel.BasicAck(eventArgs.DeliveryTag, false);
                _logger.LogInformation($"Successfully processed and acknowledged message: {eventArgs.DeliveryTag}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing message: {content}");
                _channel.BasicNack(eventArgs.DeliveryTag, false, true);
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("Stopping RabbitMQ listener");
            try
            {
                await base.StopAsync(cancellationToken);
            }
            finally
            {
                _channel?.Close();
                _connection?.Close();
            }
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
            base.Dispose();
        }
    }
}
