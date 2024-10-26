using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class CreateOrganizationCommandHandler : IRequestHandler<CreateOrganizationCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        public CreateOrganizationCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
        public async Task<Guid> Handle(CreateOrganizationCommand command, CancellationToken cancellationToken)
        {
            var organization = new Organization
            {
                Name = command.Dto.Name,
                Description = command.Dto.Description,
                Logo = command.Dto.Logo,
                Status = "Active",
                IsActive = true,
                OrganizationManager_IdOrganizationManager = command.Dto.UserId
            };

            await _unitOfWork.Organizations.AddAsync(organization);
            // Save the organization first to get its Id because it is a foreign key in the OrganizationMember table.
            // and it will cause an error if we try to add the organization member without saving the organization first.
            await _unitOfWork.CompleteAsync();

            var organizationMember = new OrganizationMember
            {
                User_IdUser = command.Dto.UserId,
                IsManager = true,
                HasAdministrativePrivilege = true,
                Organization_IdOrganization = organization.Id
            };

            await _unitOfWork.OrganizationMembers.AddAsync(organizationMember);
            await _unitOfWork.CompleteAsync();

            return organization.Id;
        }
        //  TODO: send push notification to the user to confirm the organization creation.
    }
}
