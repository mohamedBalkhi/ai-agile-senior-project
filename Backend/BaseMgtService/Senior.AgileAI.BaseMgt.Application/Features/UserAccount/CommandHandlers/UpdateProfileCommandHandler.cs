using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Exceptions;


namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.CommandHandlers
{
    public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, Guid>
    {
        private readonly IUserRepository _userRepository;
        public UpdateProfileCommandHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<Guid> Handle(UpdateProfileCommand command, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(command.DTO.UserId, cancellationToken);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {command.DTO.UserId} not found");
            }

            // Update only non-null properties
            if (command.DTO.FullName != null) user.FUllName = command.DTO.FullName;
            if (command.DTO.BirthDate.HasValue) user.BirthDate = command.DTO.BirthDate.Value;
            if (command.DTO.CountryId.HasValue) user.Country_IdCountry = command.DTO.CountryId.Value;

            _userRepository.Update(user, cancellationToken);
            return user.Id;
        }

    }
}
