using MediatR;
using Microsoft.Extensions.Configuration;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs.Calendar;
using Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.QueryHandlers;

public class GetUserSubscriptionsQueryHandler 
    : IRequestHandler<GetUserSubscriptionsQuery, List<CalendarSubscriptionDTO>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IConfiguration _configuration;
    private readonly string _baseUrl;

    public GetUserSubscriptionsQueryHandler(
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _unitOfWork = unitOfWork;
        _configuration = configuration;
        _baseUrl = _configuration["BaseUrl"] ?? "http://localhost:5000";
    }

    public async Task<List<CalendarSubscriptionDTO>> Handle(
        GetUserSubscriptionsQuery request, 
        CancellationToken cancellationToken)
    {
        var subscriptions = await _unitOfWork.CalendarSubscriptions
            .GetActiveByUserIdAsync(request.UserId, cancellationToken);

        var dtos = new List<CalendarSubscriptionDTO>();
        foreach (var subscription in subscriptions)
        {
            var feedUrl = $"{_baseUrl}/api/calendar/feed/{subscription.Token}";
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

            dtos.Add(new CalendarSubscriptionDTO
            {
                FeedUrl = feedUrl,
                ExpiresAt = subscription.ExpiresAt,
                FeedType = subscription.FeedType.ToString(),
                ProjectName = projectName,
                SeriesTitle = seriesTitle
            });
        }

        return dtos;
    }
} 