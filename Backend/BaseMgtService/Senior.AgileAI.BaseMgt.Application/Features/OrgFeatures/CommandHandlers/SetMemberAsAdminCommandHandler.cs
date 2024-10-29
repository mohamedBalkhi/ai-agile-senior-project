using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Exceptions;


namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class SetMemberAsAdminCommandHandler : IRequestHandler<SetMemberAsAdminCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;

        public SetMemberAsAdminCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
#nullable disable
        public async Task<bool> Handle(SetMemberAsAdminCommand request, CancellationToken cancellationToken)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
            user.OrganizationMember.HasAdministrativePrivilege = true;
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();
            return true;




        }
    }
}