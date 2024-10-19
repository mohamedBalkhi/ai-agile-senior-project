using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

public class LogoutCommandHandler : IRequestHandler<LogoutCommand, Unit>
{
    private readonly IAuthService _authService;

    public LogoutCommandHandler(IAuthService authService)
    {
        _authService = authService;
    }

    public async Task<Unit> Handle(LogoutCommand request, CancellationToken cancellationToken)
    {
        await _authService.LogoutAsync(request.RefreshToken);
        return Unit.Value;
    }
}