using NotificationService.Models;

namespace NotificationService.Services.Interfaces
{
    public interface IEmailNotificationService
    {
        Task SendEmailAsync(NotificationMessage message);
    }
}
