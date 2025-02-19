using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

public class LogoutCommand : IRequest<Unit>
{
    public required string RefreshToken { get; set; }
}

