using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class OrganizationMemberConfiguration : IEntityTypeConfiguration<OrganizationMember>
{
    public void Configure(EntityTypeBuilder<OrganizationMember> builder)
    {
        builder.ToTable("OrganizationMembers");

        builder.HasOne(om => om.Organization)
            .WithMany(o => o.OrganizationMembers)
            .HasForeignKey(om => om.Organization_IdOrganization);

        builder.HasOne(om => om.User)
            .WithOne(u => u.OrganizationMember)
            .HasForeignKey<OrganizationMember>(om => om.User_IdUser);

        builder.HasIndex(om => om.Organization_IdOrganization);
        builder.HasIndex(om => om.User_IdUser);
    }
} 