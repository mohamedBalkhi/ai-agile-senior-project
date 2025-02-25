using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Management.Queries;

using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.Management.QueryHandlers
{
    public class GetUsersQueryHandler : IRequestHandler<GetUsersQuery, List<UserDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public GetUsersQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

#nullable disable

        public async Task<List<UserDTO>> Handle(GetUsersQuery request, CancellationToken cancellationToken)
        {
            var users = await _unitOfWork.Users.GetUsersAsync(
                request.PageSize, 
                request.PageNumber, 
                request.Filter);

            return users.Select(user =>
            {
                return new UserDTO
                {
                    UserId = user.Id,
                    FullName = user.FUllName,
                    Email = user.Email,
                    IsActive = user.IsActive,
                    IsTrusted = user.IsTrusted,
                    IsAdmin = user.IsAdmin,
                    IsManager = user.Organization?.OrganizationManager?.Id == user.Id,
                    OrganizationId = user.Organization?.Id,
                    OrganizationName = user.Organization?.Name ?? string.Empty,
                    Country = user.Country.Name
                };
            }).ToList();
        }
    }
}