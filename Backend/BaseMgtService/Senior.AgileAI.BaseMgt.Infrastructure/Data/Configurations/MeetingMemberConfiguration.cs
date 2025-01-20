using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class MeetingMemberConfiguration : IEntityTypeConfiguration<MeetingMember>
{
    public void Configure(EntityTypeBuilder<MeetingMember> builder)
    {
        builder.ToTable("MeetingMembers");

        builder.HasOne(mm => mm.Meeting)
            .WithMany(m => m.MeetingMembers)
            .HasForeignKey(mm => mm.Meeting_IdMeeting)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(mm => mm.OrganizationMember)
            .WithMany()
            .HasForeignKey(mm => mm.OrganizationMember_IdOrganizationMember)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(mm => mm.Meeting_IdMeeting);
        builder.HasIndex(mm => mm.OrganizationMember_IdOrganizationMember);
        builder.HasIndex(mm => new { mm.Meeting_IdMeeting, mm.OrganizationMember_IdOrganizationMember }).IsUnique();
    }
} 