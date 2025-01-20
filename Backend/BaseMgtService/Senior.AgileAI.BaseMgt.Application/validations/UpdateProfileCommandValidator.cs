using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Validations
{
    public class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        
        public UpdateProfileCommandValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;

            RuleFor(x => x.UserId)
                .NotEmpty().WithMessage("User ID is required")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null;
                }).WithMessage("User not found");

            When(x => x.DTO.FullName != null, () =>
            {
                RuleFor(x => x.DTO.FullName)
                    .Length(2, 100).WithMessage("Full name must be between 2 and 100 characters")
                    .Matches("^[a-zA-Z-_. ]*$").WithMessage("Full name can only contain letters, spaces, or . - _");
            });

            When(x => x.DTO.BirthDate != null, () =>
            {
                RuleFor(x => x.DTO.BirthDate)
                    .Must(date => date <= DateOnly.FromDateTime(DateTime.Today.AddYears(-15)))
                    .WithMessage("Must be at least 15 years old");
            });

            When(x => x.DTO.CountryId != null, () =>
            {
                RuleFor(x => x.DTO.CountryId)
                    .MustAsync(async (countryId, _) =>
                    {
                        var country = await unitOfWork.Countries.GetByIdAsync(countryId.Value);
                        return country != null;
                    }).WithMessage("Invalid country selected");
            });
        }
    }
}