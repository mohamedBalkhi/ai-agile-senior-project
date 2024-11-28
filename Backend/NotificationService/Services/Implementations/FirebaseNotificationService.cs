using NotificationService.Models;
using NotificationService.Services.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace NotificationService.Services.Implementations
{
    public class FirebaseNotificationService : IFirebaseNotificationService
    {
        private readonly FirebaseMessaging _firebaseMessaging;
        private readonly ILogger<FirebaseNotificationService> _logger;

        public FirebaseNotificationService(IConfiguration configuration, ILogger<FirebaseNotificationService> logger)
        {
            _logger = logger;
            var firebaseCredentialsPath = configuration["Firebase:CredentialsPath"];
            FirebaseApp app;

            if (FirebaseApp.DefaultInstance == null)
            {
                app = FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromFile(firebaseCredentialsPath)
                });
            }
            else
            {
                app = FirebaseApp.DefaultInstance;
            }

            _firebaseMessaging = FirebaseMessaging.GetMessaging(app);
        }

        public async Task SendFirebaseNotificationAsync(NotificationMessage message)
        {
            var firebaseMessage = new Message()
            {
                Token = message.Recipient, // FCMToken of the user
                Notification = new Notification()
                {
                    Title = message.Subject,
                    Body = message.Body
                }
            };
            _logger.LogInformation($"Sending Firebase notification to {message.Recipient} with subject {message.Subject} and body {message.Body}");

            await _firebaseMessaging.SendAsync(firebaseMessage);
        }
    }
}
