using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class SetMemberAsAdminCommand : IRequest<bool>
    {
        public Guid UserId { get; set; }// from body
        public bool IsAdmin { get; set; }

        public SetMemberAsAdminCommand(Guid userId, bool isAdmin)
        {
            UserId = userId;
            IsAdmin = isAdmin;
        }
    }
}