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
using FirebaseAdmin.Messaging;
using System.Collections.Generic;
using MailKit.Net.Smtp;

namespace NotificationService.MessageHandlers
{
    public class RabbitMQListener : BackgroundService
    {
        private readonly ILogger<RabbitMQListener> _logger;
        private readonly RabbitMQOptions _rabbitMQOptions;
        private readonly IServiceProvider _serviceProvider;
        private IConnection _connection = null!;
        private IModel _channel = null!;
        private string _queueName = null!;
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

                // Periodically check connection health
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

                    // This queue declaration is idempotent, so it's safe to keep it here.
                    // If the queue already exists, it will not be recreated or cause an error.
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

                // Process the message
                await notificationHandler.HandleNotificationAsync(message);
                
                // Acknowledge successfully handled message
                _channel.BasicAck(eventArgs.DeliveryTag, false);
                _logger.LogInformation($"Successfully processed and acknowledged message: {eventArgs.DeliveryTag}");
            }
            catch (AuthenticationException authEx)
            {
                _logger.LogError(authEx, $"Permanent auth error. Will NOT requeue: {content}");
                // Don't requeue authentication errors as they're likely permanent
                _channel.BasicNack(eventArgs.DeliveryTag, false, false);
            }
            catch (SmtpCommandException smtpEx) when (smtpEx.Message.Contains("Too many login attempts"))
            {
                _logger.LogError(smtpEx, $"SMTP rate limit exceeded: {content}");
                // Move to delay queue or dead-letter exchange
                var headers = new Dictionary<string, object>
                {
                    { "x-delay", 300000 } // 5 minutes delay
                };
                var properties = _channel.CreateBasicProperties();
                properties.Headers = headers;
                
                // Publish to delay exchange if configured, otherwise don't requeue
                if (!string.IsNullOrEmpty(_rabbitMQOptions.DelayExchange))
                {
                    _channel.BasicPublish(
                        _rabbitMQOptions.DelayExchange,
                        _rabbitMQOptions.QueueName,
                        properties,
                        eventArgs.Body);
                    _channel.BasicAck(eventArgs.DeliveryTag, false);
                }
                else
                {
                    // If no delay exchange, don't requeue to prevent immediate retry
                    _channel.BasicNack(eventArgs.DeliveryTag, false, false);
                }
            }
            catch (FirebaseMessagingException firebaseEx)
            {
                _logger.LogError(firebaseEx, $"Firebase error processing message: {content}");
                // Don't requeue Firebase errors as they're likely permanent
                _channel.BasicNack(eventArgs.DeliveryTag, false, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing message: {content}");
                // Requeue for other types of errors
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
