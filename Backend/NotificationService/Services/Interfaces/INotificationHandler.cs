using NotificationService.Models;

namespace NotificationService.Services.Interfaces
{
    public interface INotificationHandler
    {
        Task HandleNotificationAsync(NotificationMessage message);
    }
}
