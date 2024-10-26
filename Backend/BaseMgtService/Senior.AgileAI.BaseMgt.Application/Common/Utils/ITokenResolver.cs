namespace Senior.AgileAI.BaseMgt.Application.Common.Utils;

public interface ITokenResolver
{
    Guid? ExtractUserId();
    string? ExtractToken();
}
