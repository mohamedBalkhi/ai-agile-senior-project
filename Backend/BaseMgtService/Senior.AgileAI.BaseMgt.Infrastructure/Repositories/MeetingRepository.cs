using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.Extensions.Logging;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class MeetingRepository : GenericRepository<Meeting>, IMeetingRepository
{
    public MeetingRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<Meeting?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.Project)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Include(m => m.RecurringPattern)
            .Include(m => m.OriginalMeeting)
                .ThenInclude(om => om!.RecurringPattern)
            .Include(m => m.RecurringInstances)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken);
    }

    public async Task<List<Meeting>> GetProjectMeetingsAsync(
        Guid projectId, 
        bool includeFullDetails = false, 
        CancellationToken cancellationToken = default)
    {
        IQueryable<Meeting> query = _context.Meetings
            .Include(m => m.Project)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User);

        if (includeFullDetails)
        {
            query = query
                .Include(m => m.RecurringPattern)
                    .ThenInclude(rp => rp.Exceptions)
                .Include(m => m.OriginalMeeting)
                .Include(m => m.RecurringInstances)
                .Include(m => m.MeetingMembers)
                    .ThenInclude(mm => mm.OrganizationMember)
                        .ThenInclude(om => om.User);
        }
        else
        {
            query = query
                .Include(m => m.RecurringPattern)
                .Include(m => m.OriginalMeeting)
                .Include(m => m.MeetingMembers);
        }

        return await query
            .Where(m => m.Project_IdProject == projectId)
            .OrderByDescending(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetMemberMeetingsAsync(Guid organizationMemberId, bool includeFullDetails = false, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.Project)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Where(m => m.MeetingMembers.Any(mm => mm.OrganizationMember_IdOrganizationMember == organizationMemberId) || m.Creator_IdOrganizationMember == organizationMemberId)
            .OrderByDescending(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetUserMeetingsAsync(Guid userId, bool includeFullDetails = false, CancellationToken cancellationToken = default)
    {
        // Log the full query execution
        var query = _context.Meetings
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Where(m => m.MeetingMembers.Any(mm => mm.OrganizationMember.User_IdUser == userId) || 
                        m.Creator.User_IdUser == userId)
            .OrderByDescending(m => m.StartTime);



        var results = await query.ToListAsync(cancellationToken);
        
        
     

        return results;
    }

    public async Task<List<Meeting>> GetUpcomingMeetingsAsync(Guid projectId, DateTime fromDate, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.Creator)
            .Include(m => m.MeetingMembers)
            .Where(m => m.Project_IdProject == projectId && 
                       m.StartTime >= fromDate && 
                       m.Status == MeetingStatus.Scheduled)
            .OrderBy(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetMeetingsByStatusAsync(Guid projectId, MeetingStatus status, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.Creator)
            .Include(m => m.MeetingMembers)
            .Where(m => m.Project_IdProject == projectId && m.Status == status)
            .OrderByDescending(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

   public async Task<bool> ValidateMeetingTimeAsync(
    Guid projectId, 
    DateTime startTimeUtc, 
    DateTime endTimeUtc, 
    Guid? excludeMeetingId = null,
    CancellationToken cancellationToken = default)
{
    var query = _context.Meetings
        .Where(m => 
            m.Project_IdProject == projectId &&
            m.Status != MeetingStatus.Completed &&
            m.Status != MeetingStatus.Cancelled &&
            m.Id != (excludeMeetingId ?? Guid.Empty));

    return !await query.AnyAsync(m =>
        (startTimeUtc >= m.StartTime && startTimeUtc < m.EndTime) ||
        (endTimeUtc > m.StartTime && endTimeUtc <= m.EndTime) ||
        (startTimeUtc <= m.StartTime && endTimeUtc >= m.EndTime),
        cancellationToken);
}

    public async Task<List<Meeting>> GetFutureRecurringInstances(
        Guid recurringPatternId, 
        DateTime fromDate,
        CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Include(m => m.RecurringPattern)
            .Include(m => m.OriginalMeeting)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Where(m => (m.RecurringPattern != null && m.RecurringPattern.Id == recurringPatternId) ||
                        (m.OriginalMeeting != null && m.OriginalMeeting.RecurringPattern.Id == recurringPatternId))
            .Where(m => m.StartTime >= fromDate && m.Status != MeetingStatus.Cancelled)
            .OrderBy(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetRecurringSeriesAsync(
        Guid recurringPatternId,
        bool includeFullDetails = false,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Meetings
            .Include(m => m.RecurringPattern)
            .Include(m => m.OriginalMeeting)
            .Include(m => m.RecurringInstances)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .Include(m => m.Creator)
                .ThenInclude(c => c.User)
            .Where(m => (m.RecurringPattern != null && m.RecurringPattern.Id == recurringPatternId) ||
                        (m.OriginalMeeting != null && m.OriginalMeeting.RecurringPattern.Id == recurringPatternId) ||
                        (m.RecurringInstances.Any(ri => ri.RecurringPattern.Id == recurringPatternId)));

        return await query
            .OrderBy(m => m.StartTime)
            .ToListAsync(cancellationToken);
    }

   public async Task<bool> HasRecurringConflictsAsync(
    Guid projectId,
    DateTime startTime,
    DateTime endTime,
    DaysOfWeek daysOfWeek,
    Guid? excludeMeetingId = null,
    CancellationToken cancellationToken = default)
{
    // Ensure input dates are in UTC
    startTime = DateTime.SpecifyKind(startTime, DateTimeKind.Utc);
    endTime = DateTime.SpecifyKind(endTime, DateTimeKind.Utc);

    var query = _context.Meetings
        .Include(m => m.RecurringPattern)
        .Where(m => m.Project_IdProject == projectId &&
                   m.Status != MeetingStatus.Cancelled &&
                   m.RecurringPattern != null &&
                   m.RecurringPattern.RecurringEndDate >= startTime);

    if (excludeMeetingId.HasValue)
    {
        query = query.Where(m => m.Id != excludeMeetingId.Value);
    }

    var potentialConflicts = await query.ToListAsync(cancellationToken);

    foreach (var meeting in potentialConflicts)
    {
        if (meeting.RecurringPattern == null) continue;

        // Skip if the recurring pattern ends before our new meeting starts
        if (meeting.RecurringPattern.RecurringEndDate < startTime)
        {
            continue;
        }

        // Check if days overlap
        if ((meeting.RecurringPattern.DaysOfWeek & daysOfWeek) != 0)
        {
            // Ensure meeting times are in UTC
            var meetingStart = DateTime.SpecifyKind(meeting.StartTime, DateTimeKind.Utc);
            var meetingEnd = DateTime.SpecifyKind(meeting.EndTime, DateTimeKind.Utc);

            // Convert to timezone for comparison
            var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(meeting.TimeZoneId);
            var meetingLocalStart = TimeZoneInfo.ConvertTimeFromUtc(meetingStart, timeZoneInfo);
            var meetingLocalEnd = TimeZoneInfo.ConvertTimeFromUtc(meetingEnd, timeZoneInfo);
            var newMeetingLocalStart = TimeZoneInfo.ConvertTimeFromUtc(startTime, timeZoneInfo);
            var newMeetingLocalEnd = TimeZoneInfo.ConvertTimeFromUtc(endTime, timeZoneInfo);

            // Get time of day for comparison
            var meetingTimeSpan = meetingLocalStart.TimeOfDay;
            var meetingEndTimeSpan = meetingLocalEnd.TimeOfDay;
            var newMeetingTimeSpan = newMeetingLocalStart.TimeOfDay;
            var newMeetingEndTimeSpan = newMeetingLocalEnd.TimeOfDay;

            if (DoTimeSpansOverlap(
                meetingTimeSpan,
                meetingEndTimeSpan,
                newMeetingTimeSpan,
                newMeetingEndTimeSpan))
            {
                Console.WriteLine(
                    $"Found time conflict: Existing meeting {meeting.Id} ({meetingTimeSpan}-{meetingEndTimeSpan}) overlaps with new meeting ({newMeetingTimeSpan}-{newMeetingEndTimeSpan})");
                return true;
            }
        }
    }

    return false;
}

private bool DoTimeSpansOverlap(TimeSpan start1, TimeSpan end1, TimeSpan start2, TimeSpan end2)
{
    // Handle cases where a meeting might span midnight
    if (end1 <= start1) // Meeting spans midnight
    {
        end1 = end1.Add(TimeSpan.FromHours(24));
    }
    if (end2 <= start2) // New meeting spans midnight
    {
        end2 = end2.Add(TimeSpan.FromHours(24));
    }

    return start1 < end2 && start2 < end1;
}

    public async Task<List<Meeting>> GetMeetingsToCompleteAsync(
        DateTime currentTimeUtc,
        int batchSize,
        CancellationToken cancellationToken)
    {
        return await _context.Meetings
            .Where(m => 
                m.Status == MeetingStatus.InProgress && 
                m.EndTime <= currentTimeUtc)
            .OrderBy(m => m.EndTime)
            .Take(batchSize)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetMeetingsNeedingRemindersAsync(
        DateTime currentTimeUtc,
        TimeSpan reminderWindow,
        int batchSize,
        CancellationToken cancellationToken)
    {
        var reminderEndTimeUtc = currentTimeUtc.Add(reminderWindow);
        
        return await _context.Meetings
            .Where(m => 
                m.Status == MeetingStatus.Scheduled &&
                m.StartTime > currentTimeUtc &&
                m.StartTime <= reminderEndTimeUtc &&
                !m.ReminderSent)
            .OrderBy(m => m.StartTime)
            .Take(batchSize)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .ToListAsync(cancellationToken);
    }
public async Task<(List<Meeting>, bool)> GetProjectMeetingsInRangeAsync(
    Guid projectId,
    DateTime? referenceDate,
    int? pageSize,
    bool upcomingOnly = false,
    string? lastMeetingIdString = null, // Use string representation of Guid
    CancellationToken cancellationToken = default)
{
    var utcNow = DateTime.UtcNow;
    int pageSizeValue = pageSize ?? 30;

    var query = _context.Meetings
        .Where(m => m.Project_IdProject == projectId);

    if (upcomingOnly)
    {
        // For upcoming view: Filter strictly after `referenceDate`
        query = query.Where(m =>
            m.EndTime > (referenceDate ?? utcNow) ||
            (m.EndTime == (referenceDate ?? utcNow) && string.Compare(m.Id.ToString(), lastMeetingIdString) != 0)); // Tie-breaking
    }
    else
    {
        // For historical view: Filter strictly before `referenceDate`
        query = query.Where(m =>
            m.EndTime < (referenceDate ?? utcNow) ||
            (m.EndTime == (referenceDate ?? utcNow) && string.Compare(m.Id.ToString(), lastMeetingIdString) != 0)); // Tie-breaking
    }

    query = upcomingOnly
        ? query.OrderBy(m => m.EndTime).ThenBy(m => m.Id) // Upcoming: Earliest first
        : query.OrderByDescending(m => m.EndTime).ThenByDescending(m => m.Id); // Historical: Latest first

    // Fetch meetings and determine if there are more
    var meetings = await query
        .Take(pageSizeValue + 1) // Fetch one extra to check for `hasMore`
        .Include(m => m.Project)
        .Include(m => m.Creator)
            .ThenInclude(c => c.User)
        .Include(m => m.MeetingMembers)
        .Include(m => m.RecurringPattern)
        .Include(m => m.OriginalMeeting)
            .ThenInclude(om => om!.RecurringPattern)
        .ToListAsync(cancellationToken);

    bool hasMore = meetings.Count > pageSizeValue;

    return (meetings.Take(pageSizeValue).ToList(), hasMore);
}
    public async Task<List<Meeting>> GetMeetingsForAIProcessingAsync(int batchSize, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Where(m => m.AudioStatus == AudioStatus.Available &&
                       m.AIProcessingStatus == AIProcessingStatus.NotStarted)
            .OrderBy(m => m.AudioUploadedAt)
            .Take(batchSize)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetMeetingsWithPendingAIProcessingAsync(int batchSize, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Where(m => (m.AIProcessingStatus == AIProcessingStatus.OnQueue ||
                        m.AIProcessingStatus == AIProcessingStatus.Processing) &&
                       m.AIProcessingToken != null)
            .OrderBy(m => m.AudioUploadedAt)
            .Take(batchSize)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Meeting>> GetActiveMeetingsAsync(MeetingType type, CancellationToken cancellationToken = default)
    {
        return await _context.Meetings
            .Where(m => m.Type == type && 
                       (m.Status == MeetingStatus.Scheduled || m.Status == MeetingStatus.InProgress))
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Meeting>> GetPastScheduledMeetingsAsync(
        DateTime currentTimeUtc,
        int batchSize,
        CancellationToken cancellationToken)
    {
        return await _context.Meetings
            .Where(m => 
                m.Status == MeetingStatus.Scheduled && 
                m.EndTime <= currentTimeUtc)
            .OrderBy(m => m.EndTime)
            .Take(batchSize)
            .Include(m => m.MeetingMembers)
                .ThenInclude(mm => mm.OrganizationMember)
                    .ThenInclude(om => om.User)
            .ToListAsync(cancellationToken);
    }

} 
