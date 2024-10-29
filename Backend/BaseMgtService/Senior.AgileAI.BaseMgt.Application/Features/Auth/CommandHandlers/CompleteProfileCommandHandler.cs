using MediatR;
using Senior.AgileAI.BaseMgt.Application.Common;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class CompleteProfileCommandHandler : IRequestHandler<CompleteProfileCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAuthService _authService;
        public CompleteProfileCommandHandler(IUnitOfWork unitOfWork, IAuthService authService)
        {
            _unitOfWork = unitOfWork;
            _authService = authService;
        }
        public async Task<bool> Handle(CompleteProfileCommand request, CancellationToken cancellationToken)
        {
            var member = await _unitOfWork.OrganizationMembers.GetByUserId(request.UserId, cancellationToken);
            member.User.FUllName = request.Dto.FullName;
            member.User.Country_IdCountry = request.Dto.CountryId;
            member.User.BirthDate = request.Dto.BirthDate;
            member.User.IsActive = true;

            member.User.Password = _authService.HashPassword(member.User, request.Dto.Password);
            await _unitOfWork.CompleteAsync();
            return true;

        }
    }
}