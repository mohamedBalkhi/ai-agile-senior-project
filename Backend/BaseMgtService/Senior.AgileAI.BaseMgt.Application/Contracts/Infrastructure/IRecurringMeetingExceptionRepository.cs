using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
public interface IRecurringMeetingExceptionRepository : IGenericRepository<RecurringMeetingException>
{
    Task<List<RecurringMeetingException>> GetByPatternAndDate(
        Guid patternId, 
        DateTime date, 
        CancellationToken cancellationToken = default);
} 