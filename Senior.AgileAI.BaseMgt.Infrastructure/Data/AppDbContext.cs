using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.Extensions.Configuration;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data;

public class PostgreSqlAppDbContext : DbContext
{
    private readonly IConfiguration _configuration;

    public PostgreSqlAppDbContext(DbContextOptions<PostgreSqlAppDbContext> options, IConfiguration configuration)
        : base(options)
    {
        _configuration = configuration;
    }
     protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseNpgsql(_configuration.GetConnectionString("PostgreSqlConnection"),
                b => b.MigrationsAssembly("Senior.AgileAI.BaseMgt.Api"));
        }
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Organization> Organizations { get; set; }
    public DbSet<OrganizationMember> OrganizationMembers { get; set; }
    public DbSet<Project> Projects { get; set; }
    public DbSet<ProjectPrivilege> ProjectPrivileges { get; set; }
    public DbSet<Country> Countries { get; set; }
    public DbSet<ProjectRequirement> ProjectRequirements { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
   

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasDefaultSchema("public");

        // Remove the TPT mapping strategy
        // modelBuilder.Entity<BaseEntity>().UseTptMappingStrategy();

        // Ignore BaseEntity as a separate entity
        modelBuilder.Ignore<BaseEntity>();

        // Configure default values for BaseEntity properties for each entity
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            if (typeof(BaseEntity).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(BaseEntity.CreatedDate))
                    .HasColumnType("timestamp without time zone")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP")
                    .ValueGeneratedOnAdd()
                    .Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);

                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(BaseEntity.UpdatedDate))
                    .HasColumnType("timestamp without time zone")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP")
                    .ValueGeneratedOnAddOrUpdate()
                    .Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);
                

                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(BaseEntity.Id))
                    .HasDefaultValueSql("gen_random_uuid()");
            }
        }

        // Configure specific tables
        modelBuilder.Entity<User>().ToTable("Users");
        modelBuilder.Entity<Country>().ToTable("Countries");
        modelBuilder.Entity<Organization>().ToTable("Organizations");
        modelBuilder.Entity<OrganizationMember>().ToTable("OrganizationMembers");
        modelBuilder.Entity<Project>().ToTable("Projects");
        modelBuilder.Entity<ProjectPrivilege>().ToTable("ProjectPrivileges");
        modelBuilder.Entity<ProjectRequirement>().ToTable("ProjectRequirements");
        modelBuilder.Entity<RefreshToken>().ToTable("RefreshTokens");

        // Configure relationships
        modelBuilder.Entity<User>()
            .HasOne(u => u.Country)
            .WithMany(c => c.Users)
            .HasForeignKey(u => u.Country_IdCountry);

        modelBuilder.Entity<User>().Property(u => u.BirthDate)
            .HasColumnType("timestamp without time zone");

        modelBuilder.Entity<RefreshToken>().HasOne(rt => rt.User)
            .WithMany(u => u.RefreshTokens)
            .HasForeignKey(rt => rt.User_IdUser);
        

        modelBuilder.Entity<OrganizationMember>()
            .HasOne(om => om.Organization)
            .WithMany(o => o.OrganizationMembers)
            .HasForeignKey(om => om.Organization_IdOrganization);

        modelBuilder.Entity<OrganizationMember>()
            .HasOne(om => om.User)
            .WithOne(u => u.OrganizationMember)
            .HasForeignKey<OrganizationMember>(om => om.User_IdUser);

        modelBuilder.Entity<Project>()
            .HasOne(p => p.Organization)
            .WithMany(o => o.Projects)
            .HasForeignKey(p => p.Organization_IdOrganization);

        modelBuilder.Entity<Project>()
            .HasOne(p => p.ProjectManager)
            .WithMany()
            .HasForeignKey(p => p.ProjectManager_IdProjectManager);

        modelBuilder.Entity<ProjectPrivilege>()
            .HasOne(pp => pp.Project)
            .WithMany(p => p.ProjectPrivileges)
            .HasForeignKey(pp => pp.Project_IdProject);

        modelBuilder.Entity<ProjectPrivilege>()
            .HasOne(pp => pp.OrganizationMember)
            .WithMany(om => om.ProjectPrivileges)
            .HasForeignKey(pp => pp.OrganizationMember_IdOrganizationMember);

        modelBuilder.Entity<ProjectRequirement>()
            .HasOne(pr => pr.Project)
            .WithMany(p => p.ProjectRequirements)
            .HasForeignKey(pr => pr.Project_IdProject);

        modelBuilder.Entity<Organization>()
            .HasOne(o => o.OrganizationManager)
            .WithMany()
            .HasForeignKey(o => o.OrganizationManager_IdOrganizationManager);

        modelBuilder.Entity<User>().Property(u => u.BirthDate)
            .HasConversion(
                d => d.ToDateTime(TimeOnly.MinValue),
                d => DateOnly.FromDateTime(d)
            );
        // Add any additional configurations here
    }
}
