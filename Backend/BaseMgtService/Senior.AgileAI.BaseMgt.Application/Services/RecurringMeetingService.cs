using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Services;

public interface IRecurringMeetingService
{
    DaysOfWeek SuggestDaysOfWeek(DateTime firstMeeting, bool excludeWeekends);
    Task<List<Meeting>> GenerateFutureInstances(Meeting baseMeeting, DateTime until);
    Task ModifyInstance(Guid meetingId, bool applyToSeries);
    Task AddException(Guid patternId, DateTime date, string reason);
    Task RescheduleInstance(Guid meetingId, DateTime newDate);
    void ValidatePattern(RecurringMeetingPattern pattern);
}

public class RecurringMeetingService : IRecurringMeetingService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<RecurringMeetingService> _logger;

    public RecurringMeetingService(IUnitOfWork unitOfWork, ILogger<RecurringMeetingService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public DaysOfWeek SuggestDaysOfWeek(DateTime firstMeeting, bool excludeWeekends)
    {
        var suggestedDays = (DaysOfWeek)(1 << ((int)firstMeeting.DayOfWeek));
        
        if (excludeWeekends)
        {
            // Remove Saturday and Sunday if they were included
            suggestedDays &= ~(DaysOfWeek.Saturday | DaysOfWeek.Sunday);
        }

        return suggestedDays;
    }
    public async Task<List<Meeting>> GenerateFutureInstances(Meeting baseMeeting, DateTime until)
    {
        if (!baseMeeting.IsRecurring || baseMeeting.RecurringPattern == null)
            throw new InvalidOperationException("Meeting is not recurring");

        ValidatePattern(baseMeeting.RecurringPattern);

        var instances = new List<Meeting>();
        var pattern = baseMeeting.RecurringPattern;
        
        // Set end date to last tick of the day
        pattern.RecurringEndDate = pattern.RecurringEndDate.Date.AddDays(1).AddTicks(-1);
        
        var currentDate = GetNextDate(baseMeeting.StartTime, pattern);
        var timeDiff = baseMeeting.EndTime - baseMeeting.StartTime;
        var reminderMinutes = (baseMeeting.StartTime - baseMeeting.ReminderTime)?.Minutes ?? 15;

        while (currentDate <= until && currentDate <= pattern.RecurringEndDate)
        {
            if (await ShouldCreateInstance(currentDate, pattern))
            {
                var instance = CreateInstance(baseMeeting, currentDate, timeDiff, reminderMinutes);
                instances.Add(instance);
            }

            currentDate = GetNextDate(currentDate, pattern);
        }

        return instances;
    }

    public async Task ModifyInstance(Guid meetingId, bool applyToSeries)
    {
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(meetingId);
        if (meeting == null)
            throw new NotFoundException("Meeting not found");

        if (!meeting.IsRecurring)
            throw new InvalidOperationException("Meeting is not part of a series");

        if (applyToSeries)
        {
            // Update all future instances
            var futureInstances = await _unitOfWork.Meetings.GetFutureRecurringInstances(
                meeting.RecurringPattern.Id,
                meeting.StartTime);

            foreach (var instance in futureInstances)
            {
                // Apply changes to each instance
                // This would be specific to what's being modified
            }
        }
        else
        {
            // Create an exception for this instance
            await AddException(meeting.RecurringPattern.Id, 
                meeting.StartTime, "Modified instance");
        }
    }

    public async Task AddException(Guid patternId, DateTime date, string reason)
    {
        // Create a record of the exception
        var exception = new RecurringMeetingException
        {
            RecurringPattern_IdRecurringPattern = patternId,
            ExceptionDate = date,
            Reason = reason
        };

        await _unitOfWork.RecurringMeetingExceptions.AddAsync(exception);
        await _unitOfWork.CompleteAsync();
    }

    public async Task RescheduleInstance(Guid meetingId, DateTime newDate)
    {
        var meeting = await _unitOfWork.Meetings.GetByIdWithDetailsAsync(meetingId);
        if (meeting == null)
            throw new NotFoundException("Meeting not found");

        var timeDiff = meeting.EndTime - meeting.StartTime;
        meeting.StartTime = newDate;
        meeting.EndTime = newDate + timeDiff;

        if (meeting.IsRecurring)
        {
            // Create an exception for the original date
            await AddException(meeting.RecurringPattern.Id, 
                meeting.StartTime, "Rescheduled");
        }

        _unitOfWork.Meetings.Update(meeting);
        await _unitOfWork.CompleteAsync();
    }

    private DateTime GetNextDate(DateTime currentDate, RecurringMeetingPattern pattern)
    {
        return pattern.RecurrenceType switch
        {
            RecurrenceType.Daily => currentDate.AddDays(pattern.Interval),
            RecurrenceType.Weekly => GetNextWeeklyDate(currentDate, pattern),
            RecurrenceType.Monthly => GetNextMonthlyDate(currentDate, pattern),
            _ => throw new ArgumentException($"Unsupported recurrence type: {pattern.RecurrenceType}")
        };
    }

    private DateTime GetNextWeeklyDate(DateTime currentDate, RecurringMeetingPattern pattern)
    {
        if (pattern.DaysOfWeek == null || pattern.DaysOfWeek == DaysOfWeek.None)
        {
            throw new InvalidOperationException("Weekly pattern must have selected days");
        }

        var nextDate = currentDate.AddDays(1);
        var startOfWeek = currentDate.AddDays(-(int)currentDate.DayOfWeek);
        var endOfWeek = startOfWeek.AddDays(6);
        var foundInCurrentWeek = false;

        // Look for next selected day in current week
        while (nextDate <= endOfWeek)
        {
            var dayFlag = (DaysOfWeek)(1 << ((int)nextDate.DayOfWeek));
            if (pattern.DaysOfWeek.Value.HasFlag(dayFlag))
            {
                foundInCurrentWeek = true;
                break;
            }
            nextDate = nextDate.AddDays(1);
        }

        // If no days found in current week or we're at week's end,
        // jump to the next week based on interval
        if (!foundInCurrentWeek || nextDate > endOfWeek)
        {
            var weeksToAdd = pattern.Interval;
            var nextWeekStart = startOfWeek.AddDays(7 * weeksToAdd);
            
            // Find first selected day in the next week
            nextDate = nextWeekStart;
            for (int i = 0; i < 7; i++)
            {
                var dayFlag = (DaysOfWeek)(1 << ((int)nextDate.DayOfWeek));
                if (pattern.DaysOfWeek.Value.HasFlag(dayFlag))
                {
                    return nextDate;
                }
                nextDate = nextDate.AddDays(1);
            }

            throw new InvalidOperationException("No valid days found in pattern");
        }

        return nextDate;
    }

    private DateTime GetNextMonthlyDate(DateTime currentDate, RecurringMeetingPattern pattern)
    {
        var nextDate = currentDate.AddMonths(pattern.Interval);
        
        // Handle end of month cases
        var originalDay = pattern.Meeting.StartTime.Day;
        var daysInMonth = DateTime.DaysInMonth(nextDate.Year, nextDate.Month);
        
        // If the original day doesn't exist in the target month, use the last day
        var targetDay = Math.Min(originalDay, daysInMonth);
        
        return new DateTime(
            nextDate.Year, 
            nextDate.Month, 
            targetDay,
            currentDate.Hour, 
            currentDate.Minute, 
            currentDate.Second,
            currentDate.Millisecond,
            currentDate.Kind);
    }

    private async Task<bool> ShouldCreateInstance(DateTime date, RecurringMeetingPattern pattern)
    {
        // Check if date is not in exceptions
        var exceptions = await _unitOfWork.RecurringMeetingExceptions
            .GetByPatternAndDate(pattern.Id, date);

        if (exceptions.Any())
            return false;

        return pattern.RecurrenceType switch
        {
            RecurrenceType.Daily => true,
            
            RecurrenceType.Weekly => pattern.DaysOfWeek?.HasFlag(
                (DaysOfWeek)(1 << ((int)date.DayOfWeek))) ?? false,
            
            RecurrenceType.Monthly => date.Day == pattern.Meeting.StartTime.Day,
            
            _ => throw new ArgumentException("Invalid recurrence type")
        };
    }

    private Meeting CreateInstance(Meeting baseMeeting, DateTime startDate, TimeSpan duration, int reminderMinutes)
    {
        return new Meeting
        {
            Title = baseMeeting.Title,
            Goal = baseMeeting.Goal,
            Language = baseMeeting.Language,
            Type = baseMeeting.Type,
            StartTime = startDate,
            EndTime = startDate + duration,
            TimeZoneId = baseMeeting.TimeZoneId,
            Location = baseMeeting.Location,
            ReminderTime = startDate.AddMinutes(-reminderMinutes),
            Project_IdProject = baseMeeting.Project_IdProject,
            Creator_IdOrganizationMember = baseMeeting.Creator_IdOrganizationMember,
            Status = MeetingStatus.Scheduled,
            OriginalMeeting_IdMeeting = baseMeeting.Id,
            MeetingMembers = baseMeeting.MeetingMembers.Select(mm => new MeetingMember
            {
                OrganizationMember_IdOrganizationMember = mm.OrganizationMember_IdOrganizationMember
            }).ToList()
        };
    }

    public void ValidatePattern(RecurringMeetingPattern pattern)
    {
        if (pattern.Interval <= 0)
            throw new ArgumentException("Interval must be greater than 0");

        if (pattern.RecurringEndDate <= DateTime.UtcNow)
            throw new ArgumentException("End date must be in the future");

        if (pattern.RecurrenceType == RecurrenceType.Weekly)
        {
            if (pattern.DaysOfWeek == null || pattern.DaysOfWeek == DaysOfWeek.None)
                throw new ArgumentException("Weekly pattern must have at least one day selected");
        }

        if (pattern.RecurrenceType == RecurrenceType.Monthly)
        {
            var day = pattern.Meeting.StartTime.Day;
            if (day > 28)
            {
                _logger.LogWarning(
                    "Monthly meeting scheduled for day {Day} may not occur in all months", 
                    day);
            }
        }
    }
} 