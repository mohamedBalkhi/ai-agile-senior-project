using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class DeActivateMemberCommandHandler : IRequestHandler<DeActivateMemberCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public DeActivateMemberCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(DeActivateMemberCommand request, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId, cancellationToken);
            user.IsActive = false;
            _unitOfWork.Users.Update(user, cancellationToken);
            var orgMember = await _unitOfWork.OrganizationMembers.GetByUserId(request.UserId, cancellationToken);
            var result = await _unitOfWork.OrganizationMembers.DeleteAsync(orgMember, cancellationToken);
            return result;

        }
    }
}