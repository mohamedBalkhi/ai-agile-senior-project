using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
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

    public AuthService(IUnitOfWork unitOfWork, IConfiguration configuration)
    {
        _unitOfWork = unitOfWork;
        _configuration = configuration;
    }

    public async Task<AuthResult> LoginAsync(string email, string password)
    {
        User? user = await _unitOfWork.Users.GetUserByEmailAsync(email, includeOrganizationMember: true);
        if (user == null || !VerifyPasswordHash(password, user.Password))
        {
            throw new UnauthorizedAccessException("Invalid credentials");
        }
        bool isAdmin = user.isAdmin || 
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
        var isAdmin = user.isAdmin || 
                       user.OrganizationMember.IsManager || 
                       user.OrganizationMember.HasAdministrativePrivilege;
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
            new Claim(ClaimTypes.Name, user.Name),
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

    /// <summary>
    /// Extracts the ClaimsPrincipal from an expired JWT token.
    /// </summary>
    /// <param name="token">The expired JWT token as a string.</param>
    /// <returns>A ClaimsPrincipal object containing the claims from the token.</returns>
    /// <remarks>
    /// This method is used primarily for refreshing tokens. It allows us to validate
    /// and extract information from an expired token without considering its expiration time.
    /// The method performs the following steps:
    /// 1. Sets up token validation parameters, disabling audience and issuer validation.
    /// 2. Validates the token's signature using the application's secret key.
    /// 3. Extracts the ClaimsPrincipal from the token.
    /// 4. Verifies that the token is a valid JWT and uses the expected HMAC-SHA256 algorithm.
    /// </remarks>
    /// <exception cref="SecurityTokenException">Thrown if the token is invalid or uses an unexpected algorithm.</exception>
    private ClaimsPrincipal GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])),
            ValidateLifetime = false
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);

        if (securityToken is not JwtSecurityToken jwtSecurityToken || 
            !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
        {
            throw new SecurityTokenException("Invalid token");
        }

        return principal;
    }

    private bool VerifyPasswordHash(string password, string storedHash)
    {
        return true;
        // Implement password verification logic here
        // For example, using BCrypt:
        // return BCrypt.Net.BCrypt.Verify(password, storedHash);
        throw new NotImplementedException("Password verification not implemented");
    }
}