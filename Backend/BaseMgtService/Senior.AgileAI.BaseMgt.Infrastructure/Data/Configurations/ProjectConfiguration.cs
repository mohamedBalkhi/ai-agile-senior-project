using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class ProjectConfiguration : IEntityTypeConfiguration<Project>
{
    public void Configure(EntityTypeBuilder<Project> builder)
    {
        builder.ToTable("Projects");

        builder.Property(p => p.Name)
            .IsRequired();

        builder.HasOne(p => p.Organization)
            .WithMany(o => o.Projects)
            .HasForeignKey(p => p.Organization_IdOrganization);

        builder.HasOne(p => p.ProjectManager)
            .WithMany()
            .HasForeignKey(p => p.ProjectManager_IdProjectManager);

        builder.HasIndex(p => p.Organization_IdOrganization);
        builder.HasIndex(p => p.ProjectManager_IdProjectManager);
    }
} 