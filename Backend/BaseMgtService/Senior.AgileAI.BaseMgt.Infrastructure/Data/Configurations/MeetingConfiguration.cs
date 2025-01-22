using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using System.Text.Json;
using System.Text.Json.Serialization;
namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class MeetingConfiguration : IEntityTypeConfiguration<Meeting>
{
    public void Configure(EntityTypeBuilder<Meeting> builder)
    {
        builder.ToTable("Meetings");

        builder.Property(m => m.Title)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(m => m.Goal)
            .HasMaxLength(1000)
            .IsRequired();

        builder.Property(m => m.Language)
            .IsRequired();

        builder.Property(m => m.Type)
            .IsRequired();

        builder.Property(m => m.Status)
            .IsRequired();

        builder.Property(m => m.StartTime)
            .HasColumnType("timestamp without time zone")
            .IsRequired();

        builder.Property(m => m.EndTime)
            .HasColumnType("timestamp without time zone")
            .IsRequired();

        builder.Property(m => m.ActualEndTime)
            .HasColumnType("timestamp without time zone")
            .IsRequired(false);

        builder.Property(m => m.TimeZoneId)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(m => m.Location)
            .HasMaxLength(500);

        builder.Property(m => m.ReminderTime)
            .HasColumnType("timestamp without time zone")
            .IsRequired();

        builder.Property(m => m.ReminderSent)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(m => m.AudioStatus)
            .IsRequired();

        builder.Property(m => m.AudioSource)
            .IsRequired();

        builder.Property(m => m.AudioUrl)
            .HasMaxLength(1000);

        builder.Property(m => m.AudioUploadedAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired(false);

        // AI Processing Configuration
        builder.Property(m => m.AIProcessingToken)
            .HasMaxLength(100)
            .IsRequired(false);

        builder.Property(m => m.AIProcessingStatus)
            .HasDefaultValue(Domain.Enums.AIProcessingStatus.NotStarted)
            .IsRequired();

        builder.Property(m => m.AIProcessedAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired(false);

        // Configure AIReport as owned entity
        builder.OwnsOne(m => m.AIReport, report =>
        {
            report.Property(r => r.Transcript)
                .HasColumnName("AITranscript")
                .HasColumnType("text");

            report.Property(r => r.Summary)
                .HasColumnName("AISummary")
                .HasColumnType("text");

            report.Property(r => r.KeyPoints)
                .HasColumnName("AIKeyPoints")
                .HasColumnType("jsonb")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, new JsonSerializerOptions()),
                    v => JsonSerializer.Deserialize<List<string>>(v, new JsonSerializerOptions()));

            report.Property(r => r.MainLanguage)
                .HasColumnName("AIMainLanguage")
                .HasMaxLength(20)
                .IsRequired();
        });

        // Online Meeting Configuration
        builder.Property(m => m.LiveKitRoomSid)
            .HasMaxLength(100)
            .IsRequired(false);

        builder.Property(m => m.LiveKitRoomName)
            .HasMaxLength(200)
            .IsRequired(false);

        builder.Property(m => m.OnlineMeetingStatus)
            .HasDefaultValue(Domain.Enums.OnlineMeetingStatus.NotStarted)
            .IsRequired();

        builder.Property(m => m.OnlineMeetingStartedAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired(false);

        builder.Property(m => m.OnlineMeetingEndedAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired(false);

        // Relationships
        builder.HasOne(m => m.Project)
            .WithMany(p => p.Meetings)
            .HasForeignKey(m => m.Project_IdProject)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(m => m.Creator)
            .WithMany()
            .HasForeignKey(m => m.Creator_IdOrganizationMember)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure self-referencing relationship
        builder.HasOne(m => m.OriginalMeeting)
            .WithMany(m => m.RecurringInstances)
            .HasForeignKey(m => m.OriginalMeeting_IdMeeting)
            .OnDelete(DeleteBehavior.Restrict);

        // Optional: Index for better query performance
        builder.HasIndex(m => m.OriginalMeeting_IdMeeting);

        // Indexes
        builder.HasIndex(m => m.StartTime);
        builder.HasIndex(m => m.Status);
        builder.HasIndex(m => m.Project_IdProject);
        builder.HasIndex(m => m.Creator_IdOrganizationMember);
    }
} 