using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class DeactivateOrganizationCommandHandler : IRequestHandler<DeactivateOrganizationCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;

        public DeactivateOrganizationCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
        }

        public async Task<bool> Handle(DeactivateOrganizationCommand request, CancellationToken cancellationToken)
        {
            var organization = await _unitOfWork.Organizations.GetByIdAsync(request.OrganizationId);
            if (organization == null)
            {
                throw new NotFoundException("Organization not found");
            }

            // Get all organization members for notifications
            var members = await _unitOfWork.OrganizationMembers.GetAllMembersAsync(organization.Id, cancellationToken);

            organization.IsActive = false;
            _unitOfWork.Organizations.Update(organization);
            await _unitOfWork.CompleteAsync();

            // Notify all members
            foreach (var member in members)
            {
                // Email notification
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Email,
                    Recipient = member.User.Email,
                    Subject = $"Organization Deactivated: {organization.Name}",
                    Body = $"The organization {organization.Name} has been deactivated."
                });

                // FCM notifications
                var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(member.User.Id, cancellationToken);
                foreach (var token in userTokens)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Firebase,
                        Recipient = token.Token,
                        Subject = "Organization Deactivated",
                        Body = $"{organization.Name} has been deactivated"
                    });
                }
            }

            return true;
        }
    }
}