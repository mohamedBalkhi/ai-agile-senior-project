using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands
{
    public class RequestPasswordResetCommand : IRequest<Guid>
    {
        public string Email { get; }

        public RequestPasswordResetCommand(string email)
        {
            Email = email;
        }
    }
}
