using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Exceptions;




namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class ResendCodeCommandHandler : IRequestHandler<ResendCodeCommand, Guid>
    {
        private readonly IUserRepository _userRepository;

        public ResendCodeCommandHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }
        public async Task<Guid> Handle(ResendCodeCommand command, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(command.UserID);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {command.UserID} not found");

            }
            else
            {
                user.Code = GenerateCode(command.UserID);
                _userRepository.Update(user);
                return user.Id;
            }
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