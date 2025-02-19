using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Calendar.Queries;

public record GetCalendarFeedQuery(string Token,string timeZondId) : IRequest<string?>; 
