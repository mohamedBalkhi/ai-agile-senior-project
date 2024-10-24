namespace NotificationService.Models
{
    public enum NotificationType
    {
        Email,
        Firebase
    }

    public class NotificationMessage
    {
        public NotificationType Type { get; set; }
        public required string Recipient { get; set; }
        public required string Subject { get; set; }
        public required string Body { get; set; }
    }
}
