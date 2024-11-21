using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.Commands;

public class UnsubscribeTokenCommand : IRequest<bool>
{
    public NotificationTokenDTO Dto { get; set; }
    public Guid UserId { get; set; }

    public UnsubscribeTokenCommand(NotificationTokenDTO dto, Guid userId)
    {
        Dto = dto;
        UserId = userId;
    }
} 