using MediatR;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.CommandHandlers
{
    public class UpdateRequirementsCommandHandler : IRequestHandler<UpdateRequirementsCommand, bool>
    {
        private readonly IUnitOfWork _unitOfWork;
        public UpdateRequirementsCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(UpdateRequirementsCommand request, CancellationToken cancellationToken)
        {
            var requirement = await _unitOfWork.ProjectRequirements.GetbyReqIdAsync(request.DTO.RequirementId);
            if (requirement == null)
                throw new Exception("Requirement not found");

            requirement.Title = request.DTO.Title ?? requirement.Title;
            requirement.Description = request.DTO.Description ?? requirement.Description;
            requirement.Status = request.DTO.Status ?? requirement.Status;
            requirement.Priority = request.DTO.Priority ?? requirement.Priority;

            var updateResult = await _unitOfWork.ProjectRequirements.UpdateAsync(requirement);
            if (!updateResult)
                return false;

            var saveResult = await _unitOfWork.CompleteAsync();
            return saveResult > 0;
        }
    }
}