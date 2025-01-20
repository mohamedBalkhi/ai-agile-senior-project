using FluentValidation;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Validations
{
    public class ChangePasswordCommandValidator : AbstractValidator<ChangePasswordCommand>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAuthService _authService;

        public ChangePasswordCommandValidator(IUnitOfWork unitOfWork, IAuthService authService)
        {
            _unitOfWork = unitOfWork;
            _authService = authService;

            RuleFor(x => x.DTO.UserId)
                .NotEmpty().WithMessage("User ID is required")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null;
                }).WithMessage("User not found")
                .MustAsync(async (userId, _) =>
                {
                    var user = await unitOfWork.Users.GetByIdAsync(userId);
                    return user != null && user.IsActive;
                }).WithMessage("User account is not active");

            RuleFor(x => x.DTO.OldPassword)
                .NotEmpty().WithMessage("Current password is required")
                .MustAsync(async (command, oldPassword, _) =>
                {
                    var user = await _unitOfWork.Users.GetByIdAsync(command.DTO.UserId);
                    return user != null && _authService.VerifyPasswordHash(user, oldPassword);
                }).WithMessage("Current password is incorrect");

            RuleFor(x => x.DTO.NewPassword)
                .NotEmpty().WithMessage("New password is required")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters")
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter")
                .Matches("[0-9]").WithMessage("Password must contain at least one number")
                .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character")
                .NotEqual(x => x.DTO.OldPassword).WithMessage("New password must be different from current password");
        }
    }
}
