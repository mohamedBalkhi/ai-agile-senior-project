using Senior.AgileAI.BaseMgt.Application.Contracts.infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IUnitOfWork : IDisposable
{
    IUserRepository Users { get; }
    ICountryRepository Countries { get; }
    IOrganizationRepository Organizations { get; }
    IProjectRepository Projects { get; }
    IOrganizationMemberRepository OrganizationMembers { get; }
    IProjectPrivilegeRepository ProjectPrivileges { get; }
    IProjectRequirementRepository ProjectRequirements { get; }
    INotificationTokenRepository NotificationTokens { get; }
    IMeetingRepository Meetings { get; }
    IMeetingMemberRepository MeetingMembers { get; }
    IRecurringMeetingPatternRepository RecurringMeetingPatterns { get; }
    IRecurringMeetingExceptionRepository RecurringMeetingExceptions { get; }
    ICalendarSubscriptionRepository CalendarSubscriptions { get; }

    Task<int> CompleteAsync();
    Task<ITransaction> BeginTransactionAsync(CancellationToken cancellationToken = default);
}
