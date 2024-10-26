using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Queries;

namespace Senior.AgileAI.BaseMgt.Application.validations
{
    public class GetProfileInfromationQueryValidator : AbstractValidator<GetProfileInfromationQuery>
    {
        private readonly IUnitOfWork _unitOfWork;
        public GetProfileInfromationQueryValidator(IUnitOfWork unitOfWork)
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