using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Commands;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Microsoft.Extensions.Configuration;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.CommandHandlers;

public class CreateCalendarSubscriptionCommandHandler 
    : IRequestHandler<CreateCalendarSubscriptionCommand, CalendarSubscriptionDTO>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IConfiguration _configuration;
    private readonly string _baseUrl;

    public CreateCalendarSubscriptionCommandHandler(
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _unitOfWork = unitOfWork;
        _configuration = configuration;
        _baseUrl = _configuration["BaseUrl"] ?? "http://localhost:5000";
    }

    public async Task<CalendarSubscriptionDTO> Handle(
        CreateCalendarSubscriptionCommand request,
        CancellationToken cancellationToken)
    {
        await ValidateSubscriptionRequestAsync(request.UserId, request.Dto, cancellationToken);
        // Check if the user has an active subscription
        
        var activeSubscription = await CheckActiveSubscriptionAsync(request.UserId, cancellationToken, request.Dto.FeedType);
        if (activeSubscription != null)
            return await CreateSubscriptionDTOAsync(activeSubscription, cancellationToken);

        var token = await GenerateUniqueTokenAsync(cancellationToken);

        var subscription = new CalendarSubscription
        {
            User_IdUser = request.UserId,
            Token = token,
            FeedType = request.Dto.FeedType,
            Project_IdProject = request.Dto.ProjectId,
            RecurringPattern_IdRecurringPattern = request.Dto.RecurringPatternId,
            ExpiresAt = DateTime.UtcNow.AddDays(request.Dto.ExpirationDays),
            IsActive = true
        };

        await _unitOfWork.CalendarSubscriptions.AddAsync(subscription, cancellationToken);
        await _unitOfWork.CompleteAsync();

        return await CreateSubscriptionDTOAsync(subscription, cancellationToken);
    }

    private async Task ValidateSubscriptionRequestAsync(
        Guid userId,
        CreateCalendarSubscriptionDTO dto,
        CancellationToken cancellationToken)
    {
        switch (dto.FeedType)
        {
            case CalendarFeedType.Project when dto.ProjectId == null:
                throw new ArgumentException("ProjectId is required for project feed type");

            case CalendarFeedType.Project:
                var projectPrivilege = await _unitOfWork.ProjectPrivileges
                    .GetPrivilegeByUserIdAsync(dto.ProjectId.Value, userId, cancellationToken);
                if (projectPrivilege?.Meetings < PrivilegeLevel.Read)
                    throw new UnauthorizedAccessException("No access to project meetings");
                break;

            case CalendarFeedType.Series when dto.RecurringPatternId == null:
                throw new ArgumentException("RecurringPatternId is required for series feed type");

            case CalendarFeedType.Series:
                var pattern = await _unitOfWork.RecurringMeetingPatterns
                    .GetByIdAsync(dto.RecurringPatternId.Value, cancellationToken);
                if (pattern == null)
                    throw new ArgumentException("Invalid recurring pattern ID");
                break;
        }
    }

    private async Task<string> GenerateUniqueTokenAsync(CancellationToken cancellationToken)
    {
        string token;
        do
        {
            token = Convert.ToBase64String(Guid.NewGuid().ToByteArray())
                .Replace("/", "_")
                .Replace("+", "-")
                .Replace("=", "");
        } while (!await _unitOfWork.CalendarSubscriptions.IsTokenUniqueAsync(token, cancellationToken));

        return token;
    }


    private async Task<CalendarSubscriptionDTO> CreateSubscriptionDTOAsync(
        CalendarSubscription subscription,
        CancellationToken cancellationToken)
    {
        var feedUrl = $"{_baseUrl}/api/Calendar/GetCalendarFeed/{subscription.Token}";
        string? projectName = null;
        string? seriesTitle = null;

        if (subscription.Project_IdProject.HasValue)
        {
            var project = await _unitOfWork.Projects
                .GetByIdAsync(subscription.Project_IdProject.Value, cancellationToken);
            projectName = project?.Name;
        }

        if (subscription.RecurringPattern_IdRecurringPattern.HasValue)
        {
            var pattern = await _unitOfWork.RecurringMeetingPatterns
                .GetByIdAsync(subscription.RecurringPattern_IdRecurringPattern.Value, cancellationToken);
            seriesTitle = pattern?.Meeting.Title;
        }

        return new CalendarSubscriptionDTO
        {
            FeedUrl = feedUrl,
            ExpiresAt = subscription.ExpiresAt,
            FeedType = subscription.FeedType.ToString(),
            ProjectName = projectName,
            SeriesTitle = seriesTitle
        };
    }

    private async Task<CalendarSubscription?> CheckActiveSubscriptionAsync(Guid userId, CancellationToken cancellationToken, CalendarFeedType feedType)
    {
        var activeSubscription = await _unitOfWork.CalendarSubscriptions
            .GetActiveByUserIdAsync(userId, cancellationToken);
        // check each type (I mean based on the type requested)
        if (activeSubscription.Any(s => s.FeedType == feedType))
            return activeSubscription.First(s => s.FeedType == feedType);
        return null;
    }
} 