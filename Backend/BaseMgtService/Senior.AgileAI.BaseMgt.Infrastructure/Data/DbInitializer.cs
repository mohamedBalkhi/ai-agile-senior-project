using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Data
{
    public static class DbInitializer
    {
        public static void Initialize(IServiceProvider serviceProvider)
        {
            using (var context = new PostgreSqlAppDbContext(
                serviceProvider.GetRequiredService<DbContextOptions<PostgreSqlAppDbContext>>(),
                serviceProvider.GetRequiredService<IConfiguration>()))
            {
                var passwordHasher = serviceProvider.GetRequiredService<IPasswordHasher<User>>();

                // Check if the database already contains seed data
                if (context.Users.Any() || context.Countries.Any() || context.Organizations.Any())
                {
                    return;   // DB has been seeded
                }

                var countries = SeedCountries();
                context.Countries.AddRange(countries);
                context.SaveChanges();

                var users = SeedUsers(countries, passwordHasher);
                context.Users.AddRange(users);
                context.SaveChanges();

                var adminUser = users.First(u => u.Email == "admin@example.com");
                var organization = SeedOrganizations(adminUser);
                context.Organizations.Add(organization);
                context.SaveChanges();

                // Update the admin user with the organization
                adminUser.Organization = organization;
                context.SaveChanges();

                var orgMember = SeedOrganizationMembers(organization, adminUser);
                context.OrganizationMembers.Add(orgMember);
                context.SaveChanges();

                var project = SeedProjects(organization, orgMember);
                context.Projects.Add(project);
                context.SaveChanges();
            }
        }

        private static List<Country> SeedCountries()
        {
            return new List<Country>
            {
                new Country { Name = "Syria", Code = "SY", IsActive = true },
                new Country { Name = "United States", Code = "US", IsActive = true },
                new Country { Name = "United Kingdom", Code = "UK", IsActive = true },
                new Country { Name = "Canada", Code = "CA", IsActive = true },
                // Add more countries as needed
            };
        }

        private static List<User> SeedUsers(List<Country> countries, IPasswordHasher<User> passwordHasher)
        {
            var usCountry = countries.First(c => c.Code == "US");
            var syCountry = countries.First(c => c.Code == "SY");

            var users = new List<User>
            {
                new User
                {
                    FUllName = "Admin User",
                    Email = "admin@example.com",
                    Password = "Admin",
                    BirthDate = new DateOnly(1990, 1, 1),
                    Country = usCountry,
                    IsActive = true,
                    IsAdmin = true,
                    IsTrusted = true,
                    Deactivated = false
                },
                new User
                {
                    FUllName = "Mohamed Al Balkhi",
                    Email = "mohamedbalkhi169@gmail.com",
                    BirthDate = new DateOnly(2002, 9, 16),
                    Password = "11223344123aS@",
                    Country = syCountry,
                    IsActive = false,
                    IsAdmin = true,
                    IsTrusted = false,
                    Deactivated = false
                },
                new User
                {
                    FUllName = "Raghad Al Hossny",
                    Email = "raghadalhosny@gmail.com",
                    BirthDate = new DateOnly(2002, 7, 1),
                    Password = "raghod1234",
                    Country = syCountry,
                    IsActive = true,
                    IsAdmin = true,
                    IsTrusted = true,
                    Deactivated = false
                },
                new User
                {
                    FUllName = "Regular User",
                    Email = "user@example.com",
                    BirthDate = new DateOnly(1995, 5, 5),
                    Country = usCountry,
                    Password = "User",
                    IsActive = true,
                    IsAdmin = false,
                    IsTrusted = false,
                    Deactivated = false
                }
            };

            // Hash passwords for each user
            foreach (var user in users)
            {
                
                user.Password = passwordHasher.HashPassword(user, user.Password);
            }

            return users;
        }

        private static Organization SeedOrganizations(User manager)
        {
            return new Organization
            {
                Name = "Default Organization",
                Status = "Active",
                Description = "Default Organization Description",
                OrganizationManager = manager
            };
        }

        private static OrganizationMember SeedOrganizationMembers(Organization organization, User user)
        {
            return new OrganizationMember
            {
                Organization = organization,
                User = user,
                IsManager = true,
                HasAdministrativePrivilege = true
            };
        }

        private static Project SeedProjects(Organization organization, OrganizationMember manager)
        {
            return new Project
            {
                Name = "Default Project",
                Status = true,
                Description = "Default Project Description",
                Organization = organization,
                ProjectManager = manager
            };
        }
    }
}