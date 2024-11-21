using MediatR;
using Microsoft.AspNetCore.Identity;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class ProjectMemberDeleteCommandHandler : IRequestHandler<ProjectMemberDeleteCommand, bool>

    {
        private readonly IUnitOfWork _unitOfWork;

        public ProjectMemberDeleteCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }


        public async Task<bool> Handle(ProjectMemberDeleteCommand request, CancellationToken cancellationToken)
        {
            var projectMember = await _unitOfWork.ProjectPrivileges.GetProjectPrivilegeByMember(request.MemberId, request.ProjectId, cancellationToken);
            if (projectMember == null)
                throw new Exception("Project member not found");

            var result = await _unitOfWork.ProjectPrivileges.DeleteAsync(projectMember, cancellationToken);
            return result;
        }

    }
}