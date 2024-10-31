using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
#nullable disable

namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers
{
    public class CreateProjectCommandHandler : IRequestHandler<CreateProjectCommand, Guid>
    {
        private readonly IUnitOfWork _unitOfWork;

        public CreateProjectCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }
        public async Task<Guid> Handle(CreateProjectCommand request, CancellationToken cancellationToken)
        {

            var user = await _unitOfWork.Users.getUserWithOrg(request.UserId, cancellationToken);
            if (user == null)
            {
                throw new NotFoundException("User not found");
            }


            var project = new Project
            {
                Name = request.Dto.ProjectName,
                Description = request.Dto.ProjectDescription,
                Status = true,
                Organization_IdOrganization = user.OrganizationMember.Organization.Id,
                ProjectManager_IdProjectManager = request.Dto.ProjectManagerId,
            };
            var addedProject = await _unitOfWork.Projects.AddAsync(project, cancellationToken);
            await _unitOfWork.CompleteAsync();
            return addedProject.Id;
        }

    }
}