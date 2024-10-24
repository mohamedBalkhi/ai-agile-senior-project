using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Models;




namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.CommandHandlers
{
    public class ResendCodeCommandHandler : IRequestHandler<ResendCodeCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;

        public ResendCodeCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
        }
        public async Task<Guid> Handle(ResendCodeCommand command, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(command.UserID,cancellationToken);
            if (user == null)
            {
                throw new NotFoundException($"User with ID {command.UserID} not found");

            }
            else
            {
                user.Code = GenerateCode();
              

                await _unitOfWork.CompleteAsync();

                  await _rabbitMQService.PublishNotificationAsync(new NotificationMessage {
                    Type = NotificationType.Email,
                    Recipient = user.Email,
                    Subject =  "Verification Code Resent",
                    Body = $"Your Verification Code is {user.Code} Please Don't share it with anybody"
                });
                
                return user.Id;
            }
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