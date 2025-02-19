using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands
{
    public class DeactivateOrganizationCommand : IRequest<bool>
    {
        public Guid OrganizationId { get; set; }
        public DeactivateOrganizationCommand(Guid organizationId)
        {
            OrganizationId = organizationId;
        }
    }
}