using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class DeactivateOrganizationCommandHandler : IRequestHandler<DeactivateOrganizationCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public DeactivateOrganizationCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(DeactivateOrganizationCommand request, CancellationToken cancellationToken)
        {
            var organization = await _unitOfWork.Organizations.GetByIdAsync(request.OrganizationId);
            if (organization == null)
            {
                throw new NotFoundException("Organization not found");
            }
            organization.IsActive = false;
            await _unitOfWork.CompleteAsync();
            return true;
        }
    }
}