using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;

public class ProjectPrivilegeConfiguration : IEntityTypeConfiguration<ProjectPrivilege>
{
    public void Configure(EntityTypeBuilder<ProjectPrivilege> builder)
    {
        builder.ToTable("ProjectPrivileges");

        builder.HasOne(pp => pp.Project)
            .WithMany(p => p.ProjectPrivileges)
            .HasForeignKey(pp => pp.Project_IdProject);

        builder.HasOne(pp => pp.OrganizationMember)
            .WithMany(om => om.ProjectPrivileges)
            .HasForeignKey(pp => pp.OrganizationMember_IdOrganizationMember);

        builder.HasIndex(pp => pp.Project_IdProject);
        builder.HasIndex(pp => pp.OrganizationMember_IdOrganizationMember);
    }
} 