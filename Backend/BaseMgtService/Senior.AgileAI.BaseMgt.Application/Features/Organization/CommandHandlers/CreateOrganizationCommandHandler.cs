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
        private readonly IOrganizationRepository _organizationRepository;
        private readonly IOrganizationMemberRepository _organizationMemberRepository;
        public CreateOrganizationCommandHandler(IOrganizationRepository organizationRepository, IOrganizationMemberRepository organizationMemberRepository)
        {
            _organizationRepository = organizationRepository;
            _organizationMemberRepository = organizationMemberRepository;
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

            var organizationAdded = await _organizationRepository.AddOrganizationAsync(organization, cancellationToken);
            var organizationMember = new OrganizationMember
            {
                User_IdUser = command.Dto.UserId,
                IsManager = true, //because only manager can create organization, so indeed it is true.
                HasAdministrativePrivilege = true,
                Organization_IdOrganization = organizationAdded.Id,
            };
            await _organizationMemberRepository.AddOrganizationMemberAsync(organizationMember, cancellationToken);
            return organizationAdded.Id;
        }
        // TODO: send email to the user to confirm the organization creation.
    }
}