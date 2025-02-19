using MediatR;
using Microsoft.Extensions.Logging;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Services;
using FluentValidation;
using FluentValidation.Results;

namespace Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;

public class CreateMeetingCommandHandler : IRequestHandler<CreateMeetingCommand, Guid>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IRecurringMeetingService _recurringMeetingService;
    private readonly IAudioStorageService _audioStorage;
    private readonly IProjectAuthorizationHelper _authHelper;
    private readonly IRabbitMQService _rabbitMQService;
    private readonly ILogger<CreateMeetingCommandHandler> _logger;
    private readonly IOnlineMeetingService _onlineMeetingService;

    public CreateMeetingCommandHandler(
        IUnitOfWork unitOfWork,
        IRecurringMeetingService recurringMeetingService,
        IAudioStorageService audioStorage,
        IProjectAuthorizationHelper authHelper,
        IRabbitMQService rabbitMQService,
        ILogger<CreateMeetingCommandHandler> logger,
        IOnlineMeetingService onlineMeetingService)
    {
        _unitOfWork = unitOfWork;
        _recurringMeetingService = recurringMeetingService;
        _audioStorage = audioStorage;
        _authHelper = authHelper;
        _rabbitMQService = rabbitMQService;
        _logger = logger;
        _onlineMeetingService = onlineMeetingService;
    }

    public async Task<Guid> Handle(CreateMeetingCommand request, CancellationToken cancellationToken)
    {
        // Authorization check
        var hasAccess = await _authHelper.HasProjectPrivilege(
            request.UserId,
            request.Dto.ProjectId,
            ProjectAspect.Meetings,
            PrivilegeLevel.Write,
            cancellationToken);

        if (!hasAccess)
        {
            throw new UnauthorizedAccessException("You don't have permission to create meetings in this project");
        }
        var member = await _unitOfWork.OrganizationMembers.GetByUserId(
            request.UserId,
            cancellationToken: cancellationToken);
        
        if (member == null)
        {
            throw new UnauthorizedAccessException("You don't have permission to create meetings in this project");
        }

        // Validate meeting time
        var isTimeValid = await _unitOfWork.Meetings.ValidateMeetingTimeAsync(
            request.Dto.ProjectId,
            request.Dto.StartTime,
            request.Dto.EndTime,
            null,
            cancellationToken);

        if (!isTimeValid)
        {
            var failures = new List<ValidationFailure>
            {
                new ValidationFailure("Time", "Meeting time conflicts with an existing meeting")
            };
            throw new ValidationException("Validation failed", failures);
        }

        // If recurring, validate pattern
        if (request.Dto.IsRecurring && request.Dto.RecurringPattern != null)
        {
            var hasConflicts = await _unitOfWork.Meetings.HasRecurringConflictsAsync(
                request.Dto.ProjectId,
                request.Dto.StartTime,
                request.Dto.EndTime,
                request.Dto.RecurringPattern.DaysOfWeek ?? DaysOfWeek.None,
                null,
                cancellationToken);

            if (hasConflicts)
            {
                var failures = new List<ValidationFailure>
                {
                    new ValidationFailure("Time", "Recurring pattern conflicts with existing meetings")
                };
                throw new ValidationException("Validation failed", failures);
            }
        }
        var membersToNotify = new List<(Guid memberId, OrganizationMember member)>();
        Meeting meeting = null!;
        string? uploadedAudioUrl = null;
        
        using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Create base meeting
            var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(request.Dto.TimeZone);

            // Convert client local time to UTC for storage
            var startTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                DateTime.SpecifyKind(request.Dto.StartTime, DateTimeKind.Unspecified), 
                timeZoneInfo);
            var endTimeUtc = TimeZoneInfo.ConvertTimeToUtc(
                DateTime.SpecifyKind(request.Dto.EndTime, DateTimeKind.Unspecified), 
                timeZoneInfo);

            // Convert reminder time to UTC
            var reminderTimeUtc = request.Dto.ReminderTime.HasValue
                ? TimeZoneInfo.ConvertTimeToUtc(
                    DateTime.SpecifyKind(request.Dto.ReminderTime.Value, DateTimeKind.Unspecified),
                    timeZoneInfo)
                : startTimeUtc.AddMinutes(-15); // Default reminder 15 minutes before start

            meeting = new Meeting
            {
                Title = request.Dto.Title,
                Goal = request.Dto.Goal ?? "",
                Language = request.Dto.Language,
                Type = request.Dto.Type,
                StartTime = startTimeUtc,
                EndTime = endTimeUtc,
                TimeZoneId = request.Dto.TimeZone,
                Location = request.Dto.Location,
                ReminderTime = reminderTimeUtc,
                Project_IdProject = request.Dto.ProjectId,
                Creator_IdOrganizationMember = member.Id,
                Status = request.Dto.Type == MeetingType.Done ? 
                    MeetingStatus.Completed : 
                    MeetingStatus.Scheduled,
                AudioStatus = request.Dto.Type == MeetingType.Done && request.Dto.AudioFile != null ? 
                    AudioStatus.Available : 
                    AudioStatus.Pending,
                AudioSource = request.Dto.Type switch
                {
                    MeetingType.Done => AudioSource.Upload,
                    MeetingType.InPerson => AudioSource.Upload,
                    MeetingType.Online => AudioSource.MeetingService,
                    _ => throw new ArgumentException("Invalid meeting type")
                }
            };

            // Upload audio if it's a Done meeting
            if (request.Dto.Type == MeetingType.Done && request.Dto.AudioFile != null)
            {
                uploadedAudioUrl = await _audioStorage.UploadAudioAsync(
                    meeting.Id,
                    request.Dto.AudioFile,
                    cancellationToken);
                meeting.AudioUrl = uploadedAudioUrl;
                meeting.AudioStatus = AudioStatus.Available;
                meeting.AudioUploadedAt = DateTime.UtcNow;
                
                // Initialize AI processing state
                meeting.AIProcessingStatus = AIProcessingStatus.NotStarted;
                meeting.AIProcessingToken = null;
                meeting.AIReport = null;
                meeting.AIProcessedAt = null;
            }

            await _unitOfWork.Meetings.AddAsync(meeting, cancellationToken);
            await _unitOfWork.CompleteAsync();

            // Handle online meeting setup
            if (request.Dto.Type == MeetingType.Online)
            {
                try
                {
                    var roomName = meeting.GenerateRoomName();
                    if (string.IsNullOrEmpty(roomName))
                    {
                        throw new InvalidOperationException("Failed to generate room name for online meeting");
                    }

                    var roomResult = await _onlineMeetingService.CreateRoomAsync(roomName, cancellationToken);
                    if (roomResult == null)
                    {
                        throw new InvalidOperationException("Failed to create online meeting room - null response from service");
                    }

                    meeting.LiveKitRoomSid = roomResult.Sid;
                    meeting.LiveKitRoomName = roomName;
                    meeting.OnlineMeetingStatus = OnlineMeetingStatus.NotStarted;
                    meeting.AudioStatus = AudioStatus.Pending;
                    meeting.AudioSource = AudioSource.MeetingService;
                    _unitOfWork.Meetings.Update(meeting);
                    await _unitOfWork.CompleteAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to create LiveKit room for meeting {MeetingId}: {Error}", meeting.Id, ex.Message);
                    throw new InvalidOperationException($"Failed to create online meeting room: {ex.Message}", ex);
                }
            }

            // Handle recurring pattern if specified
            if (request.Dto.IsRecurring && request.Dto.RecurringPattern != null)
            {
                var pattern = new RecurringMeetingPattern
                {
                    Meeting = meeting,
                    Meeting_IdMeeting = meeting.Id,
                    RecurrenceType = request.Dto.RecurringPattern.RecurrenceType,
                    Interval = request.Dto.RecurringPattern.Interval,
                    DaysOfWeek = request.Dto.RecurringPattern.DaysOfWeek,
                    RecurringEndDate = request.Dto.RecurringPattern.RecurringEndDate,
                    LastGeneratedDate = DateTime.UtcNow
                };
            
                // Validate pattern
                _recurringMeetingService.ValidatePattern(pattern);

                // Add pattern
                await _unitOfWork.RecurringMeetingPatterns.AddAsync(pattern, cancellationToken);
                await _unitOfWork.CompleteAsync();

                // Generate only up to MaxFutureInstances
                var futureInstances = await _recurringMeetingService.GenerateFutureInstances(
                    meeting, 
                    DateTime.UtcNow.AddMonths(1));

                // Take only the first MaxFutureInstances
                var instancesToCreate = futureInstances.Take(RecurringMeetingPattern.MaxFutureInstances);

                // Add members to each instance
                foreach (var instance in instancesToCreate)
                {
                    foreach (var memberId in request.Dto.MemberIds)
                    {
                        instance.MeetingMembers.Add(new MeetingMember
                        {
                            Meeting_IdMeeting = instance.Id,
                            OrganizationMember_IdOrganizationMember = memberId,
                            HasConfirmed = false
                        });
                    }
                    await _unitOfWork.Meetings.AddAsync(instance, cancellationToken);
                }
            }

            // Add members
            if (request.Dto.MemberIds.Any() || request.Dto.Type == MeetingType.Online)
            {
                foreach (var memberId in request.Dto.MemberIds)
                {
                    var meetingMember = new MeetingMember
                    {
                        Meeting_IdMeeting = meeting.Id,
                        OrganizationMember_IdOrganizationMember = memberId,
                        HasConfirmed = request.Dto.Type == MeetingType.Done ? true : false
                    };
                    await _unitOfWork.MeetingMembers.AddAsync(meetingMember, cancellationToken);

                    var orgMember = await _unitOfWork.OrganizationMembers.GetByIdAsync(
                        memberId, 
                        includeUser: true,
                        cancellationToken: cancellationToken);
                    
                    if (orgMember != null)
                    {
                        membersToNotify.Add((memberId, orgMember));
                    }
                }
            }
            
            await _unitOfWork.CompleteAsync();
            await transaction.CommitAsync(cancellationToken);

            // Send notifications after successful transaction
            var notificationBody = GetNotificationBody(meeting);
            await SendNotificationsAsync(meeting, membersToNotify, notificationBody, cancellationToken);

            return meeting.Id;
        }
        catch
        {
            Console.WriteLine("Error creating meeting");
            _logger.LogError("Error creating meeting");
            await transaction.RollbackAsync(cancellationToken);
            Console.WriteLine("Rolling back transaction");
            _logger.LogInformation("Rolling back transaction");

            Console.WriteLine($"Deleting audio file after meeting creation failure {uploadedAudioUrl}");
            _logger.LogInformation($"Deleting audio file after meeting creation failure {uploadedAudioUrl}");
            
            // If we uploaded audio, try to clean it up
            if (uploadedAudioUrl != null)
            {
                Console.WriteLine("Deleting audio file after ....");
                _logger.LogInformation("Deleting audio file after meeting creation failure");
                try
                {
                    await _audioStorage.DeleteAudioAsync(uploadedAudioUrl, cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to clean up audio file after meeting creation failure");
                }
            }
            
            throw;
        }
    }

    private string GetNotificationBody(Meeting meeting)
    {
        var baseMessage = $"Title: {meeting.Title}\nDate: {meeting.StartTime}\nGoal: {meeting.Goal}";
        
        return meeting.Type switch
        {
            MeetingType.Online => $"You have been invited to an online meeting:\n\n{baseMessage}\nA meeting link will be provided before the meeting starts.",
            MeetingType.InPerson => $"You have been invited to an in-person meeting:\n\n{baseMessage}\nLocation: {meeting.Location}",
            MeetingType.Done => $"You have been added to a completed meeting record:\n\n{baseMessage}",
            _ => baseMessage
        };
    }

    private async Task SendNotificationsAsync(
        Meeting meeting,
        List<(Guid memberId, OrganizationMember member)> membersToNotify,
        string notificationBody,
        CancellationToken cancellationToken)
    {
        try
        {
            foreach (var (memberId, orgMember) in membersToNotify)
            {
                if (orgMember.User != null)
                {
                    // Email notification
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = orgMember.User.Email,
                        Subject = $"New Meeting Invitation: {meeting.Title}",
                        Body = notificationBody
                    });

                    // Push notification
                    var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(orgMember.User.Id, cancellationToken);
                    foreach (var token in userTokens)
                    {
                        await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                        {
                            Type = NotificationType.Firebase,
                            Recipient = token.Token,
                            Subject = "New Meeting Invitation",
                            Body = notificationBody
                        });
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // Log notification failures but don't throw
            // Consider implementing a retry mechanism or queueing failed notifications
            Console.WriteLine(ex.Message);
        }
    }
}