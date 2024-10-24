using NotificationService.Models;

namespace NotificationService.Services.Interfaces
{
    public interface IFirebaseNotificationService
    {
        Task SendFirebaseNotificationAsync(NotificationMessage message);
    }
}
