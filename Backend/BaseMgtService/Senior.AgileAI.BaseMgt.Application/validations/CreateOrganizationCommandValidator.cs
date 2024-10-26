using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.validations;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.validations
{
    public class CreateOrganizationCommandValidator : AbstractValidator<CreateOrganizationCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        public CreateOrganizationCommandValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
            RuleFor(x => x.Dto.UserId)
                .NotEmpty().WithMessage("User ID is required")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null;
                }).WithMessage("User not found");
            RuleFor(x => x.Dto.Name)
                .NotEmpty().WithMessage("Name is required")
                .MinimumLength(4).WithMessage("Name must be at least 4 characters long")
                .Matches("^[a-zA-Z_]+$").WithMessage("Name can only contain letters and underscore")
                .Must(name => name.Any(char.IsUpper)).WithMessage("Name must contain at least one uppercase letter")
                .Must(name => name.Any(char.IsLower)).WithMessage("Name must contain at least one lowercase letter");
        }
    }
}
