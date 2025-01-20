using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IRecurringMeetingPatternRepository : IGenericRepository<RecurringMeetingPattern>
{
    Task<RecurringMeetingPattern?> GetByMeetingIdAsync(Guid meetingId, CancellationToken cancellationToken = default);
    Task<List<RecurringMeetingPattern>> GetActivePatternsByProjectAsync(Guid projectId, CancellationToken cancellationToken = default);
    Task<bool> HasOverlappingPatternsAsync(Guid projectId, DaysOfWeek daysOfWeek, TimeSpan startTime, TimeSpan endTime, Guid? excludePatternId = null, CancellationToken cancellationToken = default);
    Task<List<Meeting>> GetUpcomingRecurringMeetingsAsync(Guid projectId, DateTime fromDate, CancellationToken cancellationToken = default);
    Task<bool> UpdatePatternAsync(RecurringMeetingPattern pattern, CancellationToken cancellationToken = default);
    Task<bool> DeletePatternAsync(Guid patternId, bool deleteFutureMeetings = false, CancellationToken cancellationToken = default);
    Task<List<RecurringMeetingPattern>> GetActivePatternsAsync(
        DateTime currentDate,
        CancellationToken cancellationToken = default);
} 