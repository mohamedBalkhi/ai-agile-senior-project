using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class NotificationTokenConfiguration : IEntityTypeConfiguration<NotificationToken>
{
    public void Configure(EntityTypeBuilder<NotificationToken> builder)
    {
        builder.ToTable("NotificationTokens");

        builder.Property(nt => nt.Token)
            .IsRequired();

        builder.Property(nt => nt.DeviceId)
            .IsRequired();

        builder.Navigation(nt => nt.User)
            .UsePropertyAccessMode(PropertyAccessMode.Property);

        builder.HasOne(nt => nt.User)
            .WithMany(u => u.NotificationTokens)
            .HasForeignKey(nt => nt.User_IdUser)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Ignore("UserId");
    }
} 