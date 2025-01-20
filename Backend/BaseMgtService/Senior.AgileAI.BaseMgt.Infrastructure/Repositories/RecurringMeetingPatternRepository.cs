using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class RecurringMeetingPatternRepository : GenericRepository<RecurringMeetingPattern>, IRecurringMeetingPatternRepository
{
    // private readonly ILogger<RecurringMeetingPatternRepository> _logger;

    public RecurringMeetingPatternRepository(
        PostgreSqlAppDbContext context) : base(context)
    {
        // _logger = logger;
    }

    public async Task<RecurringMeetingPattern?> GetByMeetingIdAsync(
        Guid meetingId, 
        CancellationToken cancellationToken = default)
    {
        return await _context.RecurringMeetingPatterns
            .Include(rmp => rmp.Meeting)
            .FirstOrDefaultAsync(rmp => rmp.Meeting_IdMeeting == meetingId, cancellationToken);
    }

    public async Task<List<RecurringMeetingPattern>> GetActivePatternsByProjectAsync(
        Guid projectId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        return await _context.RecurringMeetingPatterns
            .Include(rmp => rmp.Meeting)
            .Where(rmp => rmp.Meeting.Project_IdProject == projectId &&
                         rmp.RecurringEndDate > now)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> HasOverlappingPatternsAsync(
        Guid projectId,
        DaysOfWeek daysOfWeek,
        TimeSpan startTime,
        TimeSpan endTime,
        Guid? excludePatternId = null,
        CancellationToken cancellationToken = default)
    {
        var query = _context.RecurringMeetingPatterns
            .Include(rmp => rmp.Meeting)
            .Where(rmp => rmp.Meeting.Project_IdProject == projectId &&
                         rmp.RecurringEndDate > DateTime.UtcNow);

        if (excludePatternId.HasValue)
        {
            query = query.Where(rmp => rmp.Id != excludePatternId.Value);
        }

        var patterns = await query.ToListAsync(cancellationToken);

        foreach (var pattern in patterns)
        {
            if ((pattern.DaysOfWeek & daysOfWeek) != 0)
            {
                var patternStart = TimeSpan.FromTicks(pattern.Meeting.StartTime.TimeOfDay.Ticks);
                var patternEnd = TimeSpan.FromTicks(pattern.Meeting.EndTime.TimeOfDay.Ticks);

                if (DoTimeSpansOverlap(startTime, endTime, patternStart, patternEnd))
                {
                    return true;
                }
            }
        }

        return false;
    }

    public async Task<List<Meeting>> GetUpcomingRecurringMeetingsAsync(
        Guid projectId,
        DateTime fromDate,
        CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.RecurringPattern)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Where(m => m.Project_IdProject == projectId &&
                       m.StartTime >= fromDate &&
                       m.Status == MeetingStatus.Scheduled &&
                       m.RecurringPattern != null)
            .OrderBy(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> UpdatePatternAsync(
        RecurringMeetingPattern pattern,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _context.RecurringMeetingPatterns.Update(pattern);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
        catch (DbUpdateConcurrencyException ex)
        {
            // _logger.LogError(ex, "Concurrency error updating pattern {PatternId}", pattern.Id);
            return false;
        }
    }

    public async Task<bool> DeletePatternAsync(
        Guid patternId,
        bool deleteFutureMeetings = false,
        CancellationToken cancellationToken = default)
    {
        var pattern = await _context.RecurringMeetingPatterns
            .Include(rmp => rmp.Meeting)
            .FirstOrDefaultAsync(rmp => rmp.Id == patternId, cancellationToken);

        if (pattern == null)
            return false;

        using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            if (deleteFutureMeetings)
            {
                var futureMeetings = await _context.Meetings
                    .Where(m => m.RecurringPattern != null &&
                               m.RecurringPattern.Id == patternId &&
                               m.StartTime > DateTime.UtcNow)
                    .ToListAsync(cancellationToken);

                _context.Meetings.RemoveRange(futureMeetings);
            }

            _context.RecurringMeetingPatterns.Remove(pattern);
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return true;
        }
        catch (Exception ex)
        {
            // _logger.LogError(ex, "Error deleting pattern {PatternId}", patternId);
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }
    }

    public async Task<List<RecurringMeetingPattern>> GetActivePatternsAsync(
        DateTime currentDate,
        CancellationToken cancellationToken = default)
{
    return await _context.RecurringMeetingPatterns
        .Include(rmp => rmp.Meeting)
        .Where(rmp => !rmp.IsCancelled &&
                     rmp.RecurringEndDate > currentDate)
            .ToListAsync(cancellationToken);
    }

    private static bool DoTimeSpansOverlap(TimeSpan start1, TimeSpan end1, TimeSpan start2, TimeSpan end2)
    {
        return start1 < end2 && start2 < end1;
    }
} 