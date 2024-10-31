using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Text;
using Senior.AgileAI.BaseMgt.Application.Models;
using System.Linq;



namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class AddOrgMembersCommandHandler : IRequestHandler<AddOrgMembersCommand, bool>
    {
        private readonly IRabbitMQService _rabbitMQService;
        private readonly IAuthService _authService;

        private readonly IUnitOfWork _unitOfWork;
        public AddOrgMembersCommandHandler(IUnitOfWork unitOfWork, IRabbitMQService rabbitMQService, IAuthService authService)
        {
            _unitOfWork = unitOfWork;
            _rabbitMQService = rabbitMQService;
            _authService = authService;
        }
        public async Task<bool> Handle(AddOrgMembersCommand request, CancellationToken cancellationToken)
        {
            using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
            try
            {
                var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
                var organization = await _unitOfWork.Organizations.GetOrganizationByUserId(request.UserId, cancellationToken);

                // Dictionary to store email-password pairs
                var emailCredentials = new Dictionary<string, (string Email, string Password)>();

                foreach (var email in request.Dto.Emails)
                {
                    var password = GenerateDefaultPassword(organization);
                    var newUser = new User
                    {
                        Email = email,
                        FUllName = "NewUser",
                        Password = password,
                        BirthDate = DateOnly.FromDateTime(DateTime.Now),
                        IsActive = false,
                        IsTrusted = true,
                        IsAdmin = false,
                        Country_IdCountry = user.Country_IdCountry,
                        Code = "00000",
                    };

                    // Store the email and password before hashing
                    emailCredentials.Add(email, (newUser.Email, password));
                    newUser.Password = _authService.HashPassword(newUser, password);
                    await _unitOfWork.Users.AddAsync(newUser, cancellationToken);
                    await _unitOfWork.CompleteAsync();

                    var orgMember = new OrganizationMember
                    {
                        User = newUser,
                        Organization = organization,
                        IsManager = false,
                        HasAdministrativePrivilege = false,
                    };

                    await _unitOfWork.OrganizationMembers.AddOrganizationMemberAsync(orgMember, cancellationToken);
                    await _unitOfWork.CompleteAsync();
                }

                await transaction.CommitAsync(cancellationToken);

                // Send emails with credentials
                foreach (var credential in emailCredentials)
                {
                    await _rabbitMQService.PublishNotificationAsync(new NotificationMessage
                    {
                        Type = NotificationType.Email,
                        Recipient = credential.Key,
                        Subject = "Welcome to " + organization.Name,
                        Body = GenerateWelcomeEmailBody(
                            organization.Name,
                            credential.Value.Email,
                            credential.Value.Password
                        )
                    });
                }

                return true;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }

        private string GenerateWelcomeEmailBody(string orgName, string email, string password)
        {
            return $@"
            Welcome to {orgName}!
            Your account has been created with the following credentials:
            Email: {email}
            Temporary Password: {password}
            Please log in and change your password as soon as possible.
            ";
        }

        public string GenerateDefaultPassword(Organization organization)
        {
            // Get first 4 characters of org name (or all if less than 4)
            var orgPrefix = organization.Name.Length >= 4
                ? organization.Name.Substring(0, 4)
                : organization.Name;

            // Generate random components
            const string upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string lower = "abcdefghijklmnopqrstuvwxyz";
            const string numbers = "0123456789";

            var random = new Random();

            // Build random string with required characters
            var randomPart = new StringBuilder();
            randomPart.Append(upper[random.Next(upper.Length)]);  // 1 uppercase
            randomPart.Append(lower[random.Next(lower.Length)]);  // 1 lowercase
            randomPart.Append(numbers[random.Next(numbers.Length)]); // 1 number
            randomPart.Append("@");  // Special character

            // Add 4 more random characters from all possible characters
            var allChars = upper + lower + numbers;
            for (int i = 0; i < 4; i++)
            {
                randomPart.Append(allChars[random.Next(allChars.Length)]);
            }

            // Combine and shuffle the random part
            var shuffledRandom = new string(
                randomPart.ToString().ToCharArray()
                .OrderBy(x => random.Next())
                .ToArray());

            // Combine org prefix with shuffled random string
            return $"{orgPrefix}{shuffledRandom}";
        }
    }
}
