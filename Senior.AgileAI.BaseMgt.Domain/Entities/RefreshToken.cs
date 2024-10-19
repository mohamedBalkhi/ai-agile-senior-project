namespace Senior.AgileAI.BaseMgt.Domain.Entities;
public class RefreshToken : BaseEntity
{
    public required string Token { get; set; } = string.Empty;
    public Guid User_IdUser { get; set; }
    public User User { get; set; } = null!;
}