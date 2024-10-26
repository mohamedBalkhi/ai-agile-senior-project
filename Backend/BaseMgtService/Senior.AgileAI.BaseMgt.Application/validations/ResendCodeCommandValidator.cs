using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;

namespace Senior.AgileAI.BaseMgt.Application.validations
{
    public class ResendCodeCommandValidator : AbstractValidator<ResendCodeCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        public ResendCodeCommandValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
            RuleFor(x => x.UserID)
                .NotEmpty().WithMessage("User ID is required")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null;
                }).WithMessage("User not found");

        }
    }
}