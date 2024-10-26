using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands
{
    public class ForgetPasswordCommand : IRequest<bool>
    {
        public Guid UserId { get; set; }
        public string NewPassword { get; set; }
        public ForgetPasswordCommand(Guid userId, string newPassword)
        {
            UserId = userId;
            NewPassword = newPassword;
        }

    }
}