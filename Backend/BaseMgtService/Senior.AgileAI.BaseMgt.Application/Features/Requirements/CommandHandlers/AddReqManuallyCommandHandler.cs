using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands;
using Senior.AgileAI.BaseMgt.Domain.Entities;


namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.CommandHandlers
{
    public class AddReqManuallyCommandHandler : IRequestHandler<AddReqManuallyCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public AddReqManuallyCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(AddReqManuallyCommand request, CancellationToken cancellationToken)
        {
            var project = await _unitOfWork.Projects.GetByIdAsync(request.DTO.ProjectId);
            if (project == null)
                throw new Exception("Project not found");

            var requirements = request.DTO.Requirements.Select(r => new ProjectRequirement
            {
                Project_IdProject = request.DTO.ProjectId,
                Title = r.Title,
                Description = r.Description,
                Status = r.Status,
                Priority = r.Priority,
            });

            await _unitOfWork.ProjectRequirements.AddRangeAsync(requirements);
            await _unitOfWork.CompleteAsync();
            return true;
        }
    }
}