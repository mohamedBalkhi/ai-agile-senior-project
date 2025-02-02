using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.BackgroundServices
{
    public class MeetingReminderWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IRabbitMQService _rabbitMQService;
        private readonly ILogger<MeetingReminderWorker> _logger;
        private readonly TimeSpan _processInterval = TimeSpan.FromMinutes(5);
        private readonly TimeSpan _reminderWindow = TimeSpan.FromHours(1);
        private const int BatchSize = 50;

        public MeetingReminderWorker(
            IServiceScopeFactory scopeFactory,
            IRabbitMQService rabbitMQService,
            ILogger<MeetingReminderWorker> logger)
        {
            _scopeFactory = scopeFactory;
            _rabbitMQService = rabbitMQService;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("{ServiceName} starting", nameof(MeetingReminderWorker));

            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

                try
                {
                    var currentTimeUtc = DateTime.UtcNow;
                    var meetings = await unitOfWork.Meetings.GetMeetingsNeedingRemindersAsync(
                        currentTimeUtc,
                        _reminderWindow,
                        BatchSize,
                        stoppingToken);

                    foreach (var meeting in meetings)
                    {
                        await SendRemindersAsync(meeting, stoppingToken);
                        meeting.ReminderSent = true;
                    }

                    if (meetings.Any())
                    {
                        await unitOfWork.CompleteAsync();
                        _logger.LogInformation(
                            "Sent reminders for {Count} meetings at {Time} UTC", 
                            meetings.Count,
                            DateTime.UtcNow);
                    }
                }
                catch (OperationCanceledException)
                {
                    _logger.LogInformation("{ServiceName} stopping", nameof(MeetingReminderWorker));
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in {ServiceName}", nameof(MeetingReminderWorker));
                }

                await Task.Delay(_processInterval, stoppingToken);
            }
        }

        private async Task SendRemindersAsync(Meeting meeting, CancellationToken cancellationToken)
        {
            foreach (var member in meeting.MeetingMembers)
            {
                if (member.OrganizationMember?.User?.Email != null)
                {
                    try
                    {
                        var notificationBody = GetNotificationBody(meeting, member.OrganizationMember);
                        
                        await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                        {
                            Type = NotificationType.Email,
                            Recipient = member.OrganizationMember.User.Email,
                            Subject = $"Reminder: {meeting.Title}",
                            Body = notificationBody
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, 
                            "Failed to send reminder for meeting {MeetingId} to user {UserId}", 
                            meeting.Id, 
                            member.OrganizationMember.User.Id);
                    }
                }
            }
        }

        private string GetNotificationBody(Meeting meeting, OrganizationMember recipient)
        {
            var recipientTimeZone = TimeZoneInfo.FindSystemTimeZoneById(meeting.TimeZoneId);
            var meetingTimeInRecipientZone = TimeZoneInfo.ConvertTimeFromUtc(
                meeting.StartTime, 
                recipientTimeZone);
            
            var timeUntilStart = meeting.StartTime - DateTime.UtcNow;
            return $"Your meeting '{meeting.Title}' starts in {(int)timeUntilStart.TotalMinutes} minutes.\n" +
                   $"Time: {meetingTimeInRecipientZone:f} ({meeting.TimeZoneId})\n" +
                   $"Location: {meeting.Location ?? meeting.MeetingUrl}\n" +
                   $"Goal: {meeting.Goal}";
        }
    }
} 