using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class OrganizationConfiguration : IEntityTypeConfiguration<Organization>
{
    public void Configure(EntityTypeBuilder<Organization> builder)
    {
        builder.ToTable("Organizations");

        builder.Property(o => o.Name)
            .IsRequired();

        builder.Property(o => o.IsActive)
            .HasDefaultValue(true)
            .IsRequired()
            .HasColumnName("IsActive");

        builder.HasOne(o => o.OrganizationManager)
            .WithOne(u => u.Organization)
            .HasForeignKey<Organization>(o => o.OrganizationManager_IdOrganizationManager)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(o => o.OrganizationManager_IdOrganizationManager);
    }
} 