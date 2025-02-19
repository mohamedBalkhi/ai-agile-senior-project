using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class CreateOrganizationCommandHandler : IRequestHandler<CreateOrganizationCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFileService _fileService;

        public CreateOrganizationCommandHandler(IUnitOfWork unitOfWork, IFileService fileService)
        {
            _unitOfWork = unitOfWork;
            _fileService = fileService;
        }

        public async Task<Guid> Handle(CreateOrganizationCommand command, CancellationToken cancellationToken)
        {
            string? logoPath = null;
            
            try
            {
                // Start transaction
                using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);

                // Save logo file if provided
                if (command.Dto.LogoFile != null)
                {
                    logoPath = await _fileService.SaveFileAsync(
                        command.Dto.LogoFile, 
                        "organization-logos", 
                        cancellationToken
                    );
                }

                var organization = new Organization
                {
                    Name = command.Dto.Name,
                    Description = command.Dto.Description,
                    Logo = logoPath,
                    Status = "Active",
                    IsActive = true,
                    OrganizationManager_IdOrganizationManager = command.Dto.UserId
                };

                await _unitOfWork.Organizations.AddAsync(organization, cancellationToken);
                await _unitOfWork.CompleteAsync();

                var organizationMember = new OrganizationMember
                {
                    User_IdUser = command.Dto.UserId,
                    IsManager = true,
                    HasAdministrativePrivilege = true,
                    Organization_IdOrganization = organization.Id
                };

                var user = await _unitOfWork.Users.GetByIdAsync(command.Dto.UserId, cancellationToken);
                user.IsActive = true;
                _unitOfWork.Users.Update(user);
                await _unitOfWork.OrganizationMembers.AddAsync(organizationMember, cancellationToken);
                await _unitOfWork.CompleteAsync();

                await transaction.CommitAsync(cancellationToken);
                return organization.Id;
            }
            catch (Exception)
            {
                // If anything fails, delete the uploaded file
                if (logoPath != null)
                {
                    await _fileService.DeleteFileAsync(logoPath);
                }
                throw;
            }
        }
        //  TODO: send push notification to the user to confirm the organization creation.
    }
}
