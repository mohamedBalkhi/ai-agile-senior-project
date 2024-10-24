namespace Senior.AgileAI.BaseMgt.Infrastructure.Options;

public class RabbitMQOptions
{
    public required string HostName { get; set; }
    public required string UserName { get; set; }
    public required string Password { get; set; }
    public Dictionary<string, string> Queues { get; set; } = new Dictionary<string, string>();
}
