namespace Senior.AgileAI.BaseMgt.Application.Models;

public enum NotificationType
{
    Email,
    Firebase
}

public class NotificationMessage
{
    public required NotificationType Type { get; set; }
    public required string Recipient { get; set; }
    public required string Subject { get; set; }
    public required string Body { get; set; }
}
