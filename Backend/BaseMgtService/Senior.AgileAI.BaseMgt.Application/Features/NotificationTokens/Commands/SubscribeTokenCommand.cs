using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.Commands;

public class SubscribeTokenCommand : IRequest<bool>
{
    public NotificationTokenDTO Dto { get; set; }
    public Guid UserId { get; set; }

    public SubscribeTokenCommand(NotificationTokenDTO dto, Guid userId)
    {
        Dto = dto;
        UserId = userId;
    }
} 