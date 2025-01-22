using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IMeetingRepository : IGenericRepository<Meeting>
{
    Task<Meeting?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetProjectMeetingsAsync(Guid projectId, bool includeFullDetails = false, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetUserMeetingsAsync(Guid userId, bool includeFullDetails = false, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetMemberMeetingsAsync(Guid organizationMemberId, bool includeFullDetails = false, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetUpcomingMeetingsAsync(Guid projectId, DateTime fromDate, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetMeetingsByStatusAsync(Guid projectId, MeetingStatus status, CancellationToken cancellationToken = default);
    Task<bool> ValidateMeetingTimeAsync(Guid projectId, DateTime startTimeUtc, DateTime endTimeUtc, Guid? excludeMeetingId = null, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetFutureRecurringInstances(
        Guid recurringPatternId, 
        DateTime fromDate,
        CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetRecurringSeriesAsync(Guid recurringPatternId, bool includeFullDetails = false, CancellationToken cancellationToken = default);
    Task<bool> HasRecurringConflictsAsync(Guid projectId, DateTime startTime, DateTime endTime, DaysOfWeek daysOfWeek, Guid? excludeMeetingId = null, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetMeetingsToCompleteAsync(DateTime currentTime, int batchSize, CancellationToken cancellationToken);
    Task<List<Meeting>> GetMeetingsNeedingRemindersAsync(DateTime currentTime, TimeSpan reminderWindow, int batchSize, CancellationToken cancellationToken);
    Task<(List<Meeting> Meetings, bool HasMorePast, bool HasMoreFuture)> GetProjectMeetingsInRangeAsync(
        Guid projectId,
        DateTime startDate,
        DateTime endDate,
        int? pageSize,
        CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetMeetingsForAIProcessingAsync(int batchSize, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetMeetingsWithPendingAIProcessingAsync(int batchSize, CancellationToken cancellationToken = default);
    Task<IEnumerable<Meeting>> GetActiveMeetingsAsync(MeetingType type, CancellationToken cancellationToken = default);
} 