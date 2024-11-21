namespace NotificationService.Options
{
    public class RabbitMQOptions
    {
        public required string HostName { get; set; }
        public required string UserName { get; set; }
        public required string Password { get; set; }
        public required string QueueName { get; set; }
        public required string VirtualHost { get; set; }
    }
}