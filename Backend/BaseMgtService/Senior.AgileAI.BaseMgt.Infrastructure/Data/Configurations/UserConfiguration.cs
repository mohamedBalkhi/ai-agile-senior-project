using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");

        builder.Navigation(u => u.NotificationTokens)
            .UsePropertyAccessMode(PropertyAccessMode.Property);

        builder.Property(u => u.Email)
            .IsRequired();

        builder.Property(u => u.BirthDate)
            .HasColumnType("timestamp without time zone")
            .HasConversion(
                d => d.ToDateTime(TimeOnly.MinValue),
                d => DateOnly.FromDateTime(d)
            );

        builder.HasOne(u => u.Country)
            .WithMany(c => c.Users)
            .HasForeignKey(u => u.Country_IdCountry);

        builder.HasIndex(u => u.Email)
            .IsUnique();
    }
} 