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
        #nullable disable
        public RabbitMQListener(
            ILogger<RabbitMQListener> logger,
            IOptions<RabbitMQOptions> rabbitMQOptions,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _rabbitMQOptions = rabbitMQOptions.Value;
            _serviceProvider = serviceProvider;

            InitializeRabbitMQListener();
        }

        private void InitializeRabbitMQListener()
        {
            _logger.LogInformation($"Initializing RabbitMQ listener with HostName: {_rabbitMQOptions.HostName}, UserName: {_rabbitMQOptions.UserName}, QueueName: {_rabbitMQOptions.QueueName}");
            
            var factory = new ConnectionFactory()
            {
                HostName = _rabbitMQOptions.HostName,
                UserName = _rabbitMQOptions.UserName,
                Password = _rabbitMQOptions.Password,
                DispatchConsumersAsync = true // Enable asynchronous consumers
            };

            int retryCount = 0;
            const int maxRetries = 5;
            const int retryDelayMs = 5000;

            while (retryCount < maxRetries)
            {
                try
                {
                    _connection = factory.CreateConnection();
                    _channel = _connection.CreateModel();
                    _queueName = _rabbitMQOptions.QueueName;

                    _channel.QueueDeclare(queue: _queueName,
                                         durable: true,
                                         exclusive: false,
                                         autoDelete: false,
                                         arguments: null);

                    _logger.LogInformation($"RabbitMQ Listener initialized. Queue '{_queueName}' declared.");
                    return;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to connect to RabbitMQ. Retry attempt {retryCount + 1} of {maxRetries}. Error: {ex.Message}");
                    retryCount++;
                    if (retryCount >= maxRetries)
                    {
                        _logger.LogError($"Failed to connect to RabbitMQ after {maxRetries} attempts. Last error: {ex.Message}");
                        throw;
                    }
                    Thread.Sleep(retryDelayMs);
                }
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            stoppingToken.ThrowIfCancellationRequested();

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += ProcessReceivedMessage;

            _logger.LogInformation($"Starting to consume messages from queue: {_queueName}");
            _channel.BasicConsume(queue: _queueName,
                                  autoAck: false,
                                  consumer: consumer);

            _logger.LogInformation($"Consumer set up successfully for queue: {_queueName}");

            // Keep the background service running until cancellation is requested
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private async Task ProcessReceivedMessage(object sender, BasicDeliverEventArgs eventArgs)
        {
            var content = Encoding.UTF8.GetString(eventArgs.Body.ToArray());
            _logger.LogInformation($"Message received from queue '{_queueName}': {content}");

            try
            {
                var notificationMessage = JsonConvert.DeserializeObject<NotificationMessage>(content);
                if (notificationMessage == null)
                {
                    throw new JsonSerializationException("Failed to deserialize notification message");
                }

                using (var scope = _serviceProvider.CreateScope())
                {
                    var notificationHandler = scope.ServiceProvider.GetRequiredService<INotificationHandler>();
                    await notificationHandler.HandleNotificationAsync(notificationMessage);
                }

                _channel.BasicAck(eventArgs.DeliveryTag, false);
                _logger.LogInformation($"Successfully processed message of type {notificationMessage.Type}");
            }
            catch (JsonSerializationException ex)
            {
                _logger.LogError(ex, "Error deserializing message.");
                _channel.BasicNack(eventArgs.DeliveryTag, false, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing message from queue '{_queueName}': {content}");
                _channel.BasicNack(eventArgs.DeliveryTag, false, false);
            }
        }

        public override void Dispose()
        {
            _channel?.Close();
            _connection?.Close();
            base.Dispose();
        }
    }
}
