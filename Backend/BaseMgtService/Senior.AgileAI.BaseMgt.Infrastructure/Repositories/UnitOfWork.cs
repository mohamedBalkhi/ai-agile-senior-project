using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.infrastructure;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly PostgreSqlAppDbContext _context;

    public IUserRepository Users { get; private set; }
    public ICountryRepository Countries { get; private set; }
    public IOrganizationRepository Organizations { get; private set; }
    public IProjectRepository Projects { get; private set; }
    public IOrganizationMemberRepository OrganizationMembers { get; private set; }
    public IProjectPrivilegeRepository ProjectPrivileges { get; private set; }
    public IProjectRequirementRepository ProjectRequirements { get; private set; }
    public INotificationTokenRepository NotificationTokens { get; private set; }
    public IMeetingRepository Meetings { get; private set; }
    public IMeetingMemberRepository MeetingMembers { get; private set; }
    public IRecurringMeetingPatternRepository RecurringMeetingPatterns { get; private set; }
    public IRecurringMeetingExceptionRepository RecurringMeetingExceptions { get; private set; }
    public ICalendarSubscriptionRepository CalendarSubscriptions { get; private set; }
    public UnitOfWork(PostgreSqlAppDbContext context)
    {
        _context = context;
        Users = new UserRepository(_context);
        Countries = new CountryRepository(_context);
        Organizations = new OrganizationRepository(_context);
        Projects = new ProjectRepository(_context);
        OrganizationMembers = new OrganizationMemberRepository(_context);
        ProjectPrivileges = new ProjectPrivilegeRepository(_context);
        ProjectRequirements = new ProjectRequirementRepository(_context);
        NotificationTokens = new NotificationTokenRepository(_context);
        Meetings = new MeetingRepository(_context);
        MeetingMembers = new MeetingMemberRepository(_context);
        RecurringMeetingPatterns = new RecurringMeetingPatternRepository(_context);
        RecurringMeetingExceptions = new RecurringMeetingExceptionRepository(_context);
        CalendarSubscriptions = new CalendarSubscriptionRepository(_context);
    }

    public async Task<int> CompleteAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public void Dispose()
    {
        _context.Dispose();
    }

    public async Task<ITransaction> BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        // Get the execution strategy
        var strategy = _context.Database.CreateExecutionStrategy();
        
        // Execute the transaction creation within the strategy
        var transaction = await strategy.ExecuteAsync(async () =>
        {
            return await _context.Database.BeginTransactionAsync(cancellationToken);
        });
        
        return new EfTransaction(transaction);
    }
}
