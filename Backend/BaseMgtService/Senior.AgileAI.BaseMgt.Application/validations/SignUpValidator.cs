using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
namespace Senior.AgileAI.BaseMgt.Application.Validations
{
    public class SignUpValidator : AbstractValidator<SignUpCommand>
    {
        private readonly IUnitOfWork _unitOfWork;

        public SignUpValidator(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
            RuleFor(x => x.DTO.Email)  // Command should contain these properties directly
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Invalid email format.")
                .MaximumLength(100).WithMessage("Email cannot exceed 100 characters.")
                .MustAsync(async (email, _) =>
                {
                    var user = await _unitOfWork.Users.GetUserByEmailAsync(email);
                    return user == null;
                }).WithMessage("This email is already registered.");

            RuleFor(x => x.DTO.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters.")
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                .Matches("[0-9]").WithMessage("Password must contain at least one number.")
                .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character.");

            RuleFor(x => x.DTO.FullName)
                .NotEmpty().WithMessage("Full name is required.")
                .Length(2, 100).WithMessage("Full name must be between 2 and 100 characters.")
                .Matches("^[a-zA-Z-_. ]*$").WithMessage("Full name can only contain letters spaces or . - _.");

            RuleFor(x => x.DTO.BirthDate)
                .NotEmpty().WithMessage("Birth date is required.")
                .Must(BeInPast).WithMessage("Birth date cannot be in the future.");

            RuleFor(x => x.DTO.Country_IdCountry)
                .NotEmpty().WithMessage("Country is required.");
        }


        private bool BeInPast(DateOnly birthDate)
        {
            return birthDate <= DateOnly.FromDateTime(DateTime.Today.AddYears(-15));
        }
    }
}
