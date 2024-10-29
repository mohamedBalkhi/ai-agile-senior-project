using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Common.Authorization
{
    public interface IProjectAuthorizationHelper
    {
        Task<bool> HasProjectPrivilege(
            Guid userId,
            Guid projectId,
            ProjectAspect aspect,
            PrivilegeLevel requiredLevel,
            CancellationToken cancellationToken);
    }
}