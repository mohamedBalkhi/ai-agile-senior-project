using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Exceptions;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.CommandHandlers
{
    public class ProfileDeactivateCommandHandler : IRequestHandler<ProfileDeactivateCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public ProfileDeactivateCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
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
            return true;
            //TODO: send an email to the user to inform them that their account has been deactivated.
            //TODO: make a schedule task to delete the user after 30 days of deactivation.
        }
    }
}