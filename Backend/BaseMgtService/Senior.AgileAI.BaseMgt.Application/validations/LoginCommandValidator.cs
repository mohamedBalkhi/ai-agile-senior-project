using Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands;
using FluentValidation;

namespace Senior.AgileAI.BaseMgt.Application.Validations{
    public class LoginCommandValidator : AbstractValidator<LoginCommand>
    {
        public LoginCommandValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email format");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required");
        }
    }
}