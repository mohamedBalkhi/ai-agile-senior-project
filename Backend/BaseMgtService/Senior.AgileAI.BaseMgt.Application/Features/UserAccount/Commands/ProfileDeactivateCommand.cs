using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands
{
    public class ProfileDeactivateCommand : IRequest<bool>
    {
        public Guid UserId { get; set; }    
        public ProfileDeactivateCommand(Guid userId)
        {
            UserId = userId;
        }
    }
}