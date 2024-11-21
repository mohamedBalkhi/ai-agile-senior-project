using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class DeActivateMemberCommand : IRequest<bool>
    {
        public Guid UserId { get; set; }
        public DeActivateMemberCommand(Guid userId)
        {
            UserId = userId; //UserID , not ORG  member id
        }
    }
}