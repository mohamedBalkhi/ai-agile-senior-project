using MediatR;
using Microsoft.AspNetCore.Identity;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class ProjectDeactivateCommandHandler : IRequestHandler<ProjectDeactivateCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProjectDeactivateCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(ProjectDeactivateCommand request, CancellationToken cancellationToken)
        {
            var project = await _unitOfWork.Projects.GetProjectByIdAsync(request.ProjectId, cancellationToken);
            if (project == null)
            {
                throw new Exception("Project not found");
            }

            project.Status = false;
            _unitOfWork.Projects.UpdateProject(project);
            await _unitOfWork.CompleteAsync();
            return true;
        }
    }
}