using NotificationService.Models;
using NotificationService.Services.Interfaces;

namespace NotificationService.Services.Implementations
{
    public class NotificationHandler : INotificationHandler
    {
        private readonly IEmailNotificationService _emailService;
        private readonly IFirebaseNotificationService _firebaseService;

        public NotificationHandler(
            IEmailNotificationService emailService,
            IFirebaseNotificationService firebaseService)
        {
            _emailService = emailService;
            _firebaseService = firebaseService;
        }

        public async Task HandleNotificationAsync(NotificationMessage message)
        {
            switch (message.Type)
            {
                case NotificationType.Email:
                    await _emailService.SendEmailAsync(message);
                    break;
                case NotificationType.Firebase:
                    await _firebaseService.SendFirebaseNotificationAsync(message);
                    break;
                default:
                    throw new NotSupportedException($"Notification type {message.Type} is not supported.");
            }
        }
    }
}
