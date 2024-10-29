using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class SetMemberAsAdminCommand : IRequest<bool>
    {
        public Guid UserId { get; set; }// from body

        public SetMemberAsAdminCommand(Guid userId)
        {
            UserId = userId;
        }
    }
}