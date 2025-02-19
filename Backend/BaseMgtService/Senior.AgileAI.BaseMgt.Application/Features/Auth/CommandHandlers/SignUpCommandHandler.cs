using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
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
            command.DTO.Email = command.DTO.Email.ToLower().Trim();
            var user = new User
            {
                FUllName = command.DTO.FullName,
                Email = command.DTO.Email.ToLower().Trim(),
                Password = command.DTO.Password,
                BirthDate = command.DTO.BirthDate,
                Country_IdCountry = command.DTO.Country_IdCountry,
                IsActive = false, //until they make new organization.
                IsTrusted = false, //need to make verify to the email first.
                IsAdmin = true, // we only allow the orgManagers to create an account.
                Deactivated = false,
            };

            // Hash the password before adding the user
            user.Password = _authService.HashPassword(user, user.Password);
            user.Code = GenerateCode();

            // Add the user and save changes in one transaction
            var createdUser = await _unitOfWork.Users.AddAsync(user, cancellationToken);
            await _unitOfWork.CompleteAsync();

            // Send notification after successful save
            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = createdUser.Email,
                Subject = "Signup",
                Body = $"Your code is {createdUser.Code}"
            });

            return createdUser.Id;
        }


        public string GenerateCode()
        {
            var _random = new Random();
            var code = _random.Next(10000, 99999).ToString("D5");
            return code;
        }
        // TODO: send the code to the user's email via event!

    }
}
