using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;

namespace Senior.AgileAI.BaseMgt.Application.validations.DeactivateProfile
{
    public class ProfileDeactivateCommandValidator : AbstractValidator<ProfileDeactivateCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        public ProfileDeactivateCommandValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
            RuleFor(x => x.UserId)
                .NotEmpty().WithMessage("User ID is required")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null;
                }).WithMessage("User not found");
        }
    }
}