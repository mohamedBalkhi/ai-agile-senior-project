using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

public class LoginCommand : IRequest<AuthResult>
{
    public required string Email { get; set; }
    public required string Password { get; set; }
}