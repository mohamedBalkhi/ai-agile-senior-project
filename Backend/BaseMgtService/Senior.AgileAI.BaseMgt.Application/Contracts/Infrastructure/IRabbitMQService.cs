using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IRabbitMQService
{
    Task PublishNotificationAsync(NotificationMessage message);
    Task PublishMessageAsync<T>(string queueName, T message) where T : class;
}
