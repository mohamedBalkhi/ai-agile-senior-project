using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.Common.Authorization;

public class ProjectAuthorizationHelper : IProjectAuthorizationHelper
{
    private readonly IUnitOfWork _unitOfWork;

    public ProjectAuthorizationHelper(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<bool> HasProjectPrivilege(
        Guid userId,
        Guid projectId,
        ProjectAspect aspect,
        PrivilegeLevel requiredLevel,
        CancellationToken cancellationToken)
    {
        var member = await _unitOfWork.OrganizationMembers
            .GetByUserId(userId, cancellationToken);

        if (member == null)
            return false;

        // Check if user is org manager (has all privileges)
        if (member.IsManager || member.HasAdministrativePrivilege)
            return true;

        var privilege = await _unitOfWork.ProjectPrivileges
            .GetPrivilegeByUserIdAsync(projectId, userId, cancellationToken);

        if (privilege == null)
            return false;

        var actualLevel = aspect switch
        {
            ProjectAspect.Meetings => privilege.Meetings,
            ProjectAspect.Settings => privilege.Settings,
            ProjectAspect.members => privilege.Members,
            ProjectAspect.Requirements => privilege.Requirements,
            ProjectAspect.Tasks => privilege.Tasks,
            _ => PrivilegeLevel.None
        };

        return actualLevel >= requiredLevel;
    }
}