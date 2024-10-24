using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IConfiguration _configuration;
    private readonly IPasswordHasher<User> _passwordHasher;

    public AuthService(IUnitOfWork unitOfWork, IConfiguration configuration, IPasswordHasher<User> passwordHasher)
    {
        _unitOfWork = unitOfWork;
        _configuration = configuration;
        _passwordHasher = passwordHasher;
    }

    public async Task<AuthResult> LoginAsync(string email, string password)
    {
        User? user = await _unitOfWork.Users.GetUserByEmailAsync(email, includeOrganizationMember: true);
        Console.WriteLine("User: " + user?.Email);
        Console.WriteLine("Password: " + password);
        Console.WriteLine("Email: " + email);
        if (user == null || !VerifyPasswordHash(user, password))
        {
            throw new UnauthorizedAccessException("Invalid credentials");
        }
        bool isAdmin = user.IsAdmin || 
                       (user.OrganizationMember?.IsManager ?? false) || 
                       (user.OrganizationMember?.HasAdministrativePrivilege ?? false);
        
        var accessToken = GenerateAccessToken(user, isAdmin);
        var refreshToken = GenerateRefreshToken(user.Id);

        user.RefreshTokens.Add(refreshToken);
        _unitOfWork.Users.Update(user);
        await _unitOfWork.CompleteAsync();

        return new AuthResult
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken.Token,
        };
    }

    public async Task<AuthResult> RefreshTokenAsync(string refreshToken)
    {
        var user = await _unitOfWork.Users.GetUserByRefreshTokenAsync(refreshToken);

        if (user == null)
        {
            throw new UnauthorizedAccessException("Invalid token");
        }

        var storedRefreshToken = user.RefreshTokens.SingleOrDefault(x => x.Token == refreshToken);

        if (storedRefreshToken == null)
        {
            throw new UnauthorizedAccessException("Invalid Refresh Token");
        }
        var isAdmin = user.IsAdmin || 
                       (user.OrganizationMember?.IsManager ?? false) || 
                       (user.OrganizationMember?.HasAdministrativePrivilege ?? false);
        var newAccessToken = GenerateAccessToken(user, isAdmin);


        return new AuthResult
        {
            AccessToken = newAccessToken,
            RefreshToken = refreshToken,
        };
    }

    public async Task LogoutAsync(string refreshToken)
    {
        var user = await _unitOfWork.Users.GetUserByRefreshTokenAsync(refreshToken);
        if (user != null)
        {
            var token = user.RefreshTokens.Single(x => x.Token == refreshToken);
            user.RefreshTokens.Remove(token);
            _unitOfWork.Users.Update(user);
            await _unitOfWork.CompleteAsync();
        }
    }

    private string GenerateAccessToken(User user, bool isAdmin)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FUllName),
            new Claim("IsAdmin", isAdmin.ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.Now.AddMinutes(Convert.ToDouble(_configuration["Jwt:AccessTokenExpirationMinutes"]));

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private RefreshToken GenerateRefreshToken(Guid userId)
    {
        return new RefreshToken
        {
            Token = Guid.NewGuid().ToString(),
            User_IdUser = userId,
        };
    }

   

    public string HashPassword(User user, string password)
    {
        return _passwordHasher.HashPassword(user, password);
    }

    public bool VerifyPasswordHash(User user, string password)
    {
        return _passwordHasher.VerifyHashedPassword(user, user.Password, password) == PasswordVerificationResult.Success;
    }
}