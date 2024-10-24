using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Constants;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class SignUpCommandHandler : IRequestHandler<SignUpCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;
        private readonly IAuthService _authService;

        public SignUpCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService, IAuthService authService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
            _authService = authService;
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
                Country_IdCountry = command.DTO.Country_IdCountry,
                IsTrusted = false, //need to make verify to the email first.
                IsAdmin = false, // we only allow the orgManagers to create an account.
            };

            var createdUser = await _unitOfWork.Users.AddAsync(user, cancellationToken);
            createdUser.Password = _authService.HashPassword(createdUser, createdUser.Password);
            createdUser.Code = GenerateCode(createdUser.Id);


            await _unitOfWork.CompleteAsync();

            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = createdUser.Email,
                Subject = "Signup",
                Body = $"Your code is {createdUser.Code}"
            });

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
