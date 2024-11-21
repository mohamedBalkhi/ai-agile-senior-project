using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class ProjectRequirementConfiguration : IEntityTypeConfiguration<ProjectRequirement>
{
    public void Configure(EntityTypeBuilder<ProjectRequirement> builder)
    {
        builder.ToTable("ProjectRequirements");

        builder.Property(e => e.Priority)
            .HasConversion<string>();

        builder.Property(e => e.Status)
            .HasConversion<string>();

        builder.HasOne(pr => pr.Project)
            .WithMany(p => p.ProjectRequirements)
            .HasForeignKey(pr => pr.Project_IdProject);

        builder.HasIndex(pr => pr.Project_IdProject);
    }
} 