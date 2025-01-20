using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;


namespace Senior.AgileAI.BaseMgt.Application.Validations
{
#nullable disable
    public class VerfiyEmailValidator : AbstractValidator<VerifyEmailCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        public VerfiyEmailValidator(IUnitOfWork unitOfWork)
        {
            RuleFor(x => x.DTO.Code)
                .NotEmpty().WithMessage("Code is required");
            RuleFor(x => x.DTO.UserId)
            .NotEmpty().WithMessage("User ID is required")
            .MustAsync(async (userId, _) =>
            {
                var user = await unitOfWork.Users.GetByIdAsync(userId);
                return user != null;
            }).WithMessage("User not found");
        }
    }
}