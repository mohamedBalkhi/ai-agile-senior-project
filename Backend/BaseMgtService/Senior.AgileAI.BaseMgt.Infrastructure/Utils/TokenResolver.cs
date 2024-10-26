using Microsoft.AspNetCore.Http;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Senior.AgileAI.BaseMgt.Application.Common.Utils;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Utils;

public class TokenResolver : ITokenResolver
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public TokenResolver(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public Guid? ExtractUserId()
    {
        var token = ExtractToken();
        if (string.IsNullOrEmpty(token))
            return null;

        try
        {
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);
            
            var userIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return null;
            }

            return userId;
        }
        catch
        {
            return null;
        }
    }

    public string? ExtractToken()
    {
        var authHeader = _httpContextAccessor.HttpContext?.Request.Headers["Authorization"].ToString();
        if (string.IsNullOrEmpty(authHeader))
            return null;

        return authHeader.Replace("Bearer ", "", StringComparison.OrdinalIgnoreCase);
    }
}
