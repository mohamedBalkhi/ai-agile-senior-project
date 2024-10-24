
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands
{
    public class ResendCodeCommand : IRequest<Guid>
    {
        public Guid UserID { get; set; }
        public ResendCodeCommand(Guid UserID)
        {
            this.UserID = UserID;
        }
    }
}