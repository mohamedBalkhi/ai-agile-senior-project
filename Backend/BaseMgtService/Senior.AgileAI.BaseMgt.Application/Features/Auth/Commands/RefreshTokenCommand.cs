using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

public class RefreshTokenCommand : IRequest<AuthResult>
{
    public required string RefreshToken { get; set; }
}