using MediatR;
using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Validations;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.CommandHandlers
{
    public class RequestPasswordResetCommandHandler : IRequestHandler<RequestPasswordResetCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;
        private readonly RequestPasswordResetValidator _validator;

        public RequestPasswordResetCommandHandler(
            IUnitOfWork unitOfWork, 
            IRabbitMQService rabbitMQService,
            RequestPasswordResetValidator validator)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
            _validator = validator;
        }

        public async Task<Guid> Handle(RequestPasswordResetCommand request, CancellationToken cancellationToken)
        {
            // Validate request
            var validationResult = await _validator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                throw new ValidationException(validationResult.Errors);
            }

            // Get user by email
            var user = await _unitOfWork.Users.GetUserByEmailAsync(request.Email);

            
            // Generate verification code
            user!.Code = GenerateCode();

            // Update user and save changes
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            // Send verification code via email
            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = user.Email,
                Subject = "Password Reset Verification Code",
                Body = $"Your verification code is {user.Code}. Please don't share it with anybody."
            });

            return user.Id;
        }

        private string GenerateCode()
        {
            var random = new Random();
            return random.Next(10000, 99999).ToString("D5");
        }
    }
}
