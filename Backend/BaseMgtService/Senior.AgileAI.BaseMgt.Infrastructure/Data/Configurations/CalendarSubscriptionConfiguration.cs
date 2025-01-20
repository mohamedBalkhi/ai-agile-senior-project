using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class CalendarSubscriptionConfiguration : IEntityTypeConfiguration<CalendarSubscription>
{
    public void Configure(EntityTypeBuilder<CalendarSubscription> builder)
    {
        builder.ToTable("CalendarSubscriptions");

        builder.Property(cs => cs.Token)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(cs => cs.FeedType)
            .IsRequired();

        builder.Property(cs => cs.ExpiresAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired();

        builder.Property(cs => cs.IsActive)
            .IsRequired()
            .HasDefaultValue(true);

        // Relationships
        builder.HasOne(cs => cs.User)
            .WithMany()
            .HasForeignKey(cs => cs.User_IdUser)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(cs => cs.Project)
            .WithMany()
            .HasForeignKey(cs => cs.Project_IdProject)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(cs => cs.RecurringPattern)
            .WithMany()
            .HasForeignKey(cs => cs.RecurringPattern_IdRecurringPattern)
            .OnDelete(DeleteBehavior.Cascade);

        // Indexes
        builder.HasIndex(cs => cs.Token).IsUnique();
        builder.HasIndex(cs => cs.User_IdUser);
        builder.HasIndex(cs => cs.Project_IdProject);
        builder.HasIndex(cs => cs.RecurringPattern_IdRecurringPattern);
        builder.HasIndex(cs => cs.ExpiresAt);
        builder.HasIndex(cs => new { cs.IsActive, cs.ExpiresAt });
    }
} 