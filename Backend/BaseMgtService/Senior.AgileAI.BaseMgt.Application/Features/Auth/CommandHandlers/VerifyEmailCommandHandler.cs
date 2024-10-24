using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Exceptions;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class VerifyEmailCommandHandler : IRequestHandler<VerifyEmailCommand, bool>

    {
        private readonly IUserRepository _userRepository;
        public VerifyEmailCommandHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<bool> Handle(VerifyEmailCommand request, CancellationToken cancellationToken)
        {
            var result = false;
            var user = await _userRepository.GetByIdAsync(request.DTO.UserId, cancellationToken);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {request.DTO.UserId} not found");
            }
            if (user.Code == request.DTO.Code)
            {
                result = true;
                user.IsTruster = true;
            }
            return result;
        }

    }
}
