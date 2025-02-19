using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.Extensions.Configuration;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data.Configurations;
using Npgsql;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data;

public class PostgreSqlAppDbContext : DbContext
{
    private readonly IConfiguration _configuration;
    private static NpgsqlDataSource? _dataSource;

    static PostgreSqlAppDbContext()
    {
        // Configure Npgsql to handle JSON serialization
        // NpgsqlConnection.GlobalTypeMapper.EnableDynamicJson();
    }

    public PostgreSqlAppDbContext(DbContextOptions<PostgreSqlAppDbContext> options, IConfiguration configuration)
        : base(options)
    {
        _configuration = configuration;
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);

        // Add this line to automatically handle DateTime conversions
        AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

        // Suppress the warning about many service providers
        optionsBuilder.ConfigureWarnings(warnings =>
            warnings.Ignore(CoreEventId.ManyServiceProvidersCreatedWarning));

        if (!optionsBuilder.IsConfigured)
        {
            var connectionString = _configuration.GetConnectionString("PostgreSqlConnection");

            // Create data source only once
            _dataSource ??= new NpgsqlDataSourceBuilder(connectionString)
                .EnableDynamicJson()
                .Build();

            optionsBuilder.UseNpgsql(_dataSource, options =>
            {
                options.MigrationsAssembly("Senior.AgileAI.BaseMgt.Api");
                // options.EnableRetryOnFailure();
            });
        }

        optionsBuilder.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
    }

    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Organization> Organizations { get; set; } = null!;
    public DbSet<OrganizationMember> OrganizationMembers { get; set; } = null!;
    public DbSet<Project> Projects { get; set; } = null!;
    public DbSet<ProjectPrivilege> ProjectPrivileges { get; set; } = null!;
    public DbSet<Country> Countries { get; set; } = null!;
    public DbSet<ProjectRequirement> ProjectRequirements { get; set; } = null!;
    public DbSet<RefreshToken> RefreshTokens { get; set; } = null!;
    public DbSet<NotificationToken> NotificationTokens { get; set; } = null!;
    public DbSet<Meeting> Meetings { get; set; } = null!;
    public DbSet<MeetingMember> MeetingMembers { get; set; } = null!;
    public DbSet<RecurringMeetingPattern> RecurringMeetingPatterns { get; set; } = null!;
    public DbSet<RecurringMeetingException> RecurringMeetingExceptions { get; set; } = null!;
    public DbSet<CalendarSubscription> CalendarSubscriptions { get; set; } = null!;
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema("public");

        modelBuilder.Ignore<BaseEntity>();

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

        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new OrganizationConfiguration());
        modelBuilder.ApplyConfiguration(new OrganizationMemberConfiguration());
        modelBuilder.ApplyConfiguration(new ProjectConfiguration());
        modelBuilder.ApplyConfiguration(new ProjectPrivilegeConfiguration());
        modelBuilder.ApplyConfiguration(new ProjectRequirementConfiguration());
        modelBuilder.ApplyConfiguration(new RefreshTokenConfiguration());
        modelBuilder.ApplyConfiguration(new NotificationTokenConfiguration());
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new MeetingConfiguration());
        modelBuilder.ApplyConfiguration(new MeetingMemberConfiguration());
        modelBuilder.ApplyConfiguration(new RecurringMeetingPatternConfiguration());
        modelBuilder.ApplyConfiguration(new RecurringMeetingExceptionConfiguration());
        modelBuilder.ApplyConfiguration(new CalendarSubscriptionConfiguration());
    }
}
