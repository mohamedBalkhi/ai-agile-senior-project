using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using System.Text;
using System.Security.Cryptography;
using System.Linq;



namespace Senior.AgileAI.BaseMgt.Application.Features.OrgFeatures.CommandHandlers
{
    public class AddOrgMemberHandler : IRequestHandler<AddOrgMember, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public AddOrgMemberHandler(IUnitOfWork unitOfWork, IAuthService authService)
        {
            _unitOfWork = unitOfWork;
        }
        public async Task<bool> Handle(AddOrgMember request, CancellationToken cancellationToken)
        {
            using var transaction = await _unitOfWork.BeginTransactionAsync(cancellationToken);
            try
            {
                var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
                var organization = await _unitOfWork.Organizations.GetOrganizationByUserId(request.UserId, cancellationToken);
                Console.WriteLine(organization.Id);

                foreach (var email in request.Dto.Emails)
                {
                    var NewUser = new User
                    {
                        Email = email,
                        FUllName = "NewUser",
                        Password = GenerateDefaultPassword(organization),
                        BirthDate = DateOnly.FromDateTime(DateTime.Now),
                        Status = "Active",
                        IsTrusted = true,
                        IsAdmin = false,
                        Country_IdCountry = user.Country_IdCountry, //TODO: change to organization country
                        Code = "00000",
                        Organization = organization,

                    };
                    await _unitOfWork.Users.AddAsync(NewUser, cancellationToken);
                    await _unitOfWork.CompleteAsync();

                    var orgMember = new OrganizationMember
                    {
                        User = NewUser,
                        Organization = organization,
                        IsManager = false,
                        HasAdministrativePrivilege = false,
                    };
                    await _unitOfWork.OrganizationMembers.AddOrganizationMemberAsync(orgMember, cancellationToken);
                    await _unitOfWork.CompleteAsync();
                }
                await transaction.CommitAsync(cancellationToken);
                return true;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
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
