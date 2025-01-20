using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.CommandHandlers
{
    public class ProfileDeactivateCommandHandler : IRequestHandler<ProfileDeactivateCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;

        public ProfileDeactivateCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
        }

        public async Task<bool> Handle(ProfileDeactivateCommand command, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(command.UserId, cancellationToken);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {command.UserId} not found");
            }

            user.IsActive = false;
            await _unitOfWork.CompleteAsync();

            // Send email notification
            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = user.Email,
                Subject = "Account Deactivated",
                Body = "Your account has been deactivated."
            });

            // Send FCM notification
            var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(user.Id, cancellationToken);
            foreach (var token in userTokens)
            {
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Firebase,
                    Recipient = token.Token,
                    Subject = "Account Deactivated",
                    Body = "Your account has been deactivated"
                });
            }

            return true;
        }
    }
}