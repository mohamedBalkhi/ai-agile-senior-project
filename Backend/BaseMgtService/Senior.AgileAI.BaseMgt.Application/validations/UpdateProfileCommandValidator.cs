using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;
#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.validations
{
    public class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        public UpdateProfileCommandValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
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