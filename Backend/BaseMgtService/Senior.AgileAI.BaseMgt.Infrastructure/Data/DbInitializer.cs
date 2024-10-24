using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using System;
using System.Linq;
using System.Collections.Generic;

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
                // Check if the database already contains seed data
                if (context.Users.Any() || context.Countries.Any() || context.Organizations.Any())
                {
                    return;   // DB has been seeded
                }

                var countries = SeedCountries();
                var users = SeedUsers(countries);
                var organization = SeedOrganizations(users);
                var orgMember = SeedOrganizationMembers(organization, users);
                var project = SeedProjects(organization, orgMember);

                context.Countries.AddRange(countries);
                context.Users.AddRange(users);
                context.Organizations.Add(organization);
                context.OrganizationMembers.Add(orgMember);
                context.Projects.Add(project);

                // Save changes in a specific order to avoid circular dependency issues
                context.SaveChanges();
                context.Entry(organization).State = EntityState.Detached;
                context.Entry(orgMember).State = EntityState.Detached;
                context.Entry(project).State = EntityState.Detached;

                organization.OrganizationManager = orgMember;
                context.Organizations.Update(organization);
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

        private static List<User> SeedUsers(List<Country> countries)
        {
            var usCountry = countries.First(c => c.Code == "US");
            var syCountry = countries.First(c => c.Code == "SY");

            return new List<User>
            {
                new User
                {
                    Name = "Admin User",
                    Email = "admin@example.com",
                    Password = "Admin", // In real scenario, use a proper password hashing method
                    BirthDate = new DateOnly(1990, 1, 1),
                    Country = usCountry,
                    Status = "Active",
                    IsAdmin = true,
                    IsTruster = true
                },
                new User 
                {
                    Name = "Mohamed Al Balkhi",
                    Email = "mohamedbalkhi169@gmail.com",
                    Password = "11223344123aS@",
                    BirthDate = new DateOnly(2002, 9, 16),
                    Country = syCountry,
                    Status = "Active",
                        IsAdmin = true,
                    IsTruster = true
                },
                 new User 
                {
                    Name = "Raghad Al Hossny",
                    Email = "raghodalhosny@gmail.com",
                    Password = "raghod1234",
                    BirthDate = new DateOnly(2002, 7, 1),
                    Country = syCountry,
                    Status = "Active",
                    IsAdmin = true,
                    IsTruster = true
                },
                new User
                {
                    Name = "Regular User",
                    Email = "user@example.com",
                    Password = "Regular",
                    BirthDate = new DateOnly(1995, 5, 5),
                    Country = usCountry,
                    Status = "Active",
                    IsAdmin = false,
                    IsTruster = false
                }
            };
        }

        private static Organization SeedOrganizations(List<User> users)
        {
            var adminUser = users.First(u => u.Email == "admin@example.com");

            var organization = new Organization
            {
                Name = "Default Organization",
                Status = "Active",
                Description = "Default Organization Description",
            };

            return organization;
        }

        private static OrganizationMember SeedOrganizationMembers(Organization organization, List<User> users)
        {
            var adminUser = users.First(u => u.Email == "admin@example.com");

            var orgMember = new OrganizationMember
            {
                Organization = organization,
                User = adminUser,
                IsManager = true,
                HasAdministrativePrivilege = true
            };

            return orgMember;
        }

        private static Project SeedProjects(Organization organization, OrganizationMember manager)
        {
            return new Project
            {
                Name = "Default Project",
                Status = "Active",
                Description = "Default Project Description",
                Organization = organization,
                ProjectManager = manager
            };
        }
    }
}