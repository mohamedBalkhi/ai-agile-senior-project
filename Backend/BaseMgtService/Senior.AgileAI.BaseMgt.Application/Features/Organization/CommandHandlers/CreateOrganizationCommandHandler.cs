using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
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
                OrganizationManager_IdOrganizationManager = command.Dto.UserId
            };

            await _unitOfWork.Organizations.AddAsync(organization);
            var organizationMember = new OrganizationMember
            {
                User_IdUser = command.Dto.UserId,
                IsManager = true, //because only manager can create organization, so indeed it is true.
                HasAdministrativePrivilege = true,
                Organization = organization
            };
            await _unitOfWork.OrganizationMembers.AddAsync(organizationMember);
            await _unitOfWork.CompleteAsync();
            return organization.Id;
        }
        // TODO: send email to the user to confirm the organization creation.
    }
}