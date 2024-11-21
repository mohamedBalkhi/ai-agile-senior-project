namespace Senior.AgileAI.BaseMgt.Domain.Entities;

public class NotificationToken : BaseEntity
{
    public required string Token { get; set; }
    public required string DeviceId { get; set; }
    public required Guid User_IdUser { get; set; }
    public virtual User User { get; set; } = null!;
}
