using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Exceptions;


namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.CommandHandlers
{
    public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        public UpdateProfileCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> Handle(UpdateProfileCommand command, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(command.DTO.UserId, cancellationToken);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {command.DTO.UserId} not found");
            }

            // Update only non-null properties
            if (command.DTO.FullName != null) user.FUllName = command.DTO.FullName;
            if (command.DTO.BirthDate.HasValue) user.BirthDate = command.DTO.BirthDate.Value;
            if (command.DTO.CountryId.HasValue) user.Country_IdCountry = command.DTO.CountryId.Value;

            await _unitOfWork.CompleteAsync();
            return user.Id;
        }

    }
}
