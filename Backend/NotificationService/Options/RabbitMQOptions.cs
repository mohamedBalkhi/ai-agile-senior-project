namespace NotificationService.Options
{
    public class RabbitMQOptions
    {
        public string HostName { get; set; } = "localhost";
        public string UserName { get; set; } = "guest";
        public string Password { get; set; } = "guest";
        public string QueueName { get; set; } = "notifications_queue";
        public string VirtualHost { get; set; } = "/";
        public string DelayExchange { get; set; } = "notifications.delay";
    }
}