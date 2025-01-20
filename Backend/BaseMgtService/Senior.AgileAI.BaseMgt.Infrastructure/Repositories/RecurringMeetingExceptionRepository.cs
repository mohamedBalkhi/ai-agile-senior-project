using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class RecurringMeetingExceptionRepository : GenericRepository<RecurringMeetingException>, IRecurringMeetingExceptionRepository
{
    public RecurringMeetingExceptionRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<List<RecurringMeetingException>> GetByPatternAndDate(
        Guid patternId, 
        DateTime date,
        CancellationToken cancellationToken = default)
    {
        return await _context.RecurringMeetingExceptions
            .Where(e => e.RecurringPattern_IdRecurringPattern == patternId && 
                       e.ExceptionDate.Date == date.Date)
            .ToListAsync(cancellationToken);
    }
} 