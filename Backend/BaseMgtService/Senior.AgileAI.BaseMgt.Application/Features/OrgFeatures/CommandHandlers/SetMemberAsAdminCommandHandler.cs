using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Exceptions;
using Senior.AgileAI.BaseMgt.Application.Models;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class SetMemberAsAdminCommandHandler : IRequestHandler<SetMemberAsAdminCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IRabbitMQService _rabbitMQService;

        public SetMemberAsAdminCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
        }

        public async Task<bool> Handle(SetMemberAsAdminCommand request, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, includeOrganizationMember: true);
            if (user == null)
            {
                throw new NotFoundException("User not found");
            }

            var organization = await _unitOfWork.Organizations.GetByIdAsync(user.OrganizationMember.Organization_IdOrganization);
            user.OrganizationMember.HasAdministrativePrivilege = request.IsAdmin;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();

            // Send email notification
            await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
            {
                Type = NotificationType.Email,
                Recipient = user.Email,
                Subject = "Admin Status Update",
                Body = $"Your admin privileges have been {(request.IsAdmin ? "granted" : "revoked")} for {organization.Name}"
            });

            // Send FCM notification
            var userTokens = await _unitOfWork.NotificationTokens.GetTokensByUserId(user.Id, cancellationToken);
            foreach (var token in userTokens)
            {
                await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                {
                    Type = NotificationType.Firebase,
                    Recipient = token.Token,
                    Subject = "Admin Status Changed",
                    Body = $"Your admin status has been {(request.IsAdmin ? "granted" : "revoked")}"
                });
            }

            return true;
        }
    }
}