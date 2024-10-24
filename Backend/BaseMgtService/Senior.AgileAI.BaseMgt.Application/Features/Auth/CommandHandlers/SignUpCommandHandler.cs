using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class SignUpCommandHandler : IRequestHandler<SignUpCommand, Guid>
    {
        private readonly IUserRepository _userRepository;

        public SignUpCommandHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<Guid> Handle(SignUpCommand command, CancellationToken cancellationToken)
        {
            var user = new User
            {
                FUllName = command.DTO.Name,
                Email = command.DTO.Email,
                Password = command.DTO.Password,
                BirthDate = command.DTO.BirthDate,
                Status = "active",
                IsTruster = false, //need to make verify to the email first.
                IsAdmin = false, // we only allow the orgManagers to create an account.
            };

            var createdUser = await _userRepository.AddAsync(user, cancellationToken);
            createdUser.Code = GenerateCode(createdUser.Id);
            _userRepository.Update(createdUser, cancellationToken);
            return createdUser.Id;
        }


        public string GenerateCode(Guid userId)
        {
            var _random = new Random();
            var code = _random.Next(10000, 99999).ToString("D5");
            return code;
        }
        // TODO: send the code to the user's email via event!

    }
}