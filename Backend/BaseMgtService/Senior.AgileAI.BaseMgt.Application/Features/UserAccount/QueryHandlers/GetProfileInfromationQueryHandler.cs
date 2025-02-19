using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Queries;
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.QueryHandlers
{
    public class GetProfileInfromationQueryHandler : IRequestHandler<GetProfileInfromationQuery, ProfileDTO>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetProfileInfromationQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ProfileDTO> Handle(GetProfileInfromationQuery query, CancellationToken cancellationToken)
        {
            // Modify your repository to include related entities
            var user = await _unitOfWork.Users
                .GetProfileInformation(query.UserId, cancellationToken);

            if (user == null)
            {
                throw new NotFoundException("User not found");
            }

            return new ProfileDTO()
            {
                FullName = user.FUllName,
                Email = user.Email,
                CountryName = user.Country.Name,  // Use null conditional operator
                BirthDate = user.BirthDate,
                OrganizationName = user.Organization?.Name ?? user.OrganizationMember?.Organization?.Name
            };
        }
    }
}
