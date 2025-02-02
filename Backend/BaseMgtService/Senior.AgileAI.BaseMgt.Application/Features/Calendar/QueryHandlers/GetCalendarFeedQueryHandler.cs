using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Ical.Net.CalendarComponents;
using Ical.Net.DataTypes;
using Ical.Net.Serialization;
using Microsoft.Extensions.Logging;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.QueryHandlers;

public class GetCalendarFeedQueryHandler : IRequestHandler<GetCalendarFeedQuery, string?>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<GetCalendarFeedQueryHandler> _logger;
    public GetCalendarFeedQueryHandler(IUnitOfWork unitOfWork, ILogger<GetCalendarFeedQueryHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<string?> Handle(GetCalendarFeedQuery request, CancellationToken cancellationToken)
    {
        var subscription = await _unitOfWork.CalendarSubscriptions.GetByTokenAsync(
            request.Token, 
            cancellationToken);

        if (subscription == null || !subscription.IsActive || subscription.ExpiresAt <= DateTime.UtcNow)
            throw new UnauthorizedAccessException("Invalid or expired calendar token");

        var calendar = new Ical.Net.Calendar();
        calendar.Method = "PUBLISH";
        calendar.ProductId = "-//AgileMeets//Calendar//EN";

        var meetings = subscription.FeedType switch
        {
            CalendarFeedType.Personal => await _unitOfWork.Meetings
                .GetUserMeetingsAsync(subscription.User_IdUser, true, false,cancellationToken),
                
            CalendarFeedType.Project => await _unitOfWork.Meetings
                .GetProjectMeetingsAsync(subscription.Project_IdProject!.Value, true, cancellationToken),
                
            CalendarFeedType.Series => await _unitOfWork.Meetings
                .GetRecurringSeriesAsync(subscription.RecurringPattern_IdRecurringPattern!.Value, true, cancellationToken),
                
            _ => throw new ArgumentException($"Unsupported feed type: {subscription.FeedType}")
        };

        _logger.LogInformation("Found {MeetingCount} meetings for subscription {SubscriptionId}", meetings.Count, subscription.Id);
        var userTimeZone = TimeZoneInfo.FindSystemTimeZoneById(request.timeZondId);
        foreach (var meeting in meetings)
        {
            var startTime = TimeZoneInfo.ConvertTimeFromUtc(meeting.StartTime, userTimeZone);
            var EndTime = TimeZoneInfo.ConvertTimeFromUtc(meeting.EndTime, userTimeZone);
            var calendarEvent = new CalendarEvent
            {
                Summary = meeting.Title,
                Description = $"Goal: {meeting.Goal}\n" +
                             $"Type: {meeting.Type}\n" +
                             $"Language: {meeting.Language}\n" +
                             $"Members: {string.Join(", ", meeting.MeetingMembers.Select(m => m.OrganizationMember.User.FUllName))}\n" +
                             $"Meeting ID: {meeting.Id}", // Include meeting ID for deep linking
                Start = new CalDateTime(startTime),
                End = new CalDateTime(EndTime),
                Location = meeting.Location ?? meeting.MeetingUrl,
                Uid = meeting.Id.ToString(),
                Created = new CalDateTime(meeting.CreatedDate),
                LastModified = new CalDateTime(meeting.UpdatedDate),
                Status = meeting.Status switch
                {
                    MeetingStatus.Scheduled => "CONFIRMED",
                    MeetingStatus.Cancelled => "CANCELLED",
                    MeetingStatus.InProgress => "IN-PROGRESS",
                    MeetingStatus.Completed => "COMPLETED",
                    _ => "TENTATIVE"
                }
            };

            // Add custom properties using the Properties collection
            calendarEvent.Properties.Set("X-MEETING-ID", meeting.Id.ToString());
            calendarEvent.Properties.Set("X-MEETING-TYPE", meeting.Type);
            calendarEvent.Properties.Set("X-PROJECT-ID", meeting.Project_IdProject.ToString());
            calendarEvent.Properties.Set("X-CREATOR-ID", meeting.Creator_IdOrganizationMember.ToString());
            calendarEvent.Properties.Set("X-IS-RECURRING", meeting.IsRecurring.ToString());
            calendarEvent.Properties.Set("X-MEETING-STATUS", meeting.Status.ToString());

            // Add organizer
            if (meeting.Creator?.User != null)
            {
                calendarEvent.Organizer = new Organizer
                {
                    CommonName = meeting.Creator.User.FUllName,
                    Value = new Uri($"mailto:{meeting.Creator.User.Email}")
                };
            }

            calendar.Events.Add(calendarEvent);
        }

        // Use the serializer to generate proper iCal format
        var serializer = new CalendarSerializer();
        return serializer.SerializeToString(calendar);
    }
}