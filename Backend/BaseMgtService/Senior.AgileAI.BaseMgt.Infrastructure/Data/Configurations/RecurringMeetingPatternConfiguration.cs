using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class RecurringMeetingPatternConfiguration : IEntityTypeConfiguration<RecurringMeetingPattern>
{
    public void Configure(EntityTypeBuilder<RecurringMeetingPattern> builder)
    {
        builder.ToTable("RecurringMeetingPatterns");

        builder.Property(rmp => rmp.RecurrenceType).IsRequired();
        builder.Property(rmp => rmp.Interval).IsRequired();
        builder.Property(rmp => rmp.RecurringEndDate).HasColumnType("timestamp without time zone").IsRequired();

        builder.HasOne(rmp => rmp.Meeting)
            .WithOne(m => m.RecurringPattern)
            .HasForeignKey<RecurringMeetingPattern>(rmp => rmp.Meeting_IdMeeting)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(rmp => rmp.Meeting_IdMeeting).IsUnique();
        builder.HasIndex(rmp => rmp.RecurringEndDate);
    }
} 