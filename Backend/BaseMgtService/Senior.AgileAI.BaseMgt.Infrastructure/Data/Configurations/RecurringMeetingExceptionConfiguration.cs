using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class RecurringMeetingExceptionConfiguration : IEntityTypeConfiguration<RecurringMeetingException>
{
    public void Configure(EntityTypeBuilder<RecurringMeetingException> builder)
    {
        builder.ToTable("RecurringMeetingExceptions");

        builder.Property(e => e.ExceptionDate).HasColumnType("timestamp without time zone").IsRequired();
        builder.Property(e => e.Reason).IsRequired();

        builder.HasOne(e => e.RecurringPattern)
            .WithMany(rmp => rmp.Exceptions)
            .HasForeignKey(e => e.RecurringPattern_IdRecurringPattern)
            .OnDelete(DeleteBehavior.Cascade);

        // Add indexes
        builder.HasIndex(e => e.RecurringPattern_IdRecurringPattern);
        builder.HasIndex(e => e.ExceptionDate);
        builder.HasIndex(e => new { e.RecurringPattern_IdRecurringPattern, e.ExceptionDate });
    }
} 