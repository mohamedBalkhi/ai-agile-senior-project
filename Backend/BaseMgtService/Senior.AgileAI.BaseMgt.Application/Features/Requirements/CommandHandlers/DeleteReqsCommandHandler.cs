using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands;


namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.CommandHandlers
{
    public class DeleteReqsCommandHandler : IRequestHandler<DeleteReqsCommand, List<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public DeleteReqsCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<List<bool>> Handle(DeleteReqsCommand request, CancellationToken cancellationToken)
        {
            var results = new List<bool>();
            var transaction = await _unitOfWork.BeginTransactionAsync();
            try
            {
                foreach (var id in request.RequirementIds)
                {
                    var requirement = await _unitOfWork.ProjectRequirements.GetbyReqIdAsync(id);
                    if (requirement == null)
                        throw new Exception("Requirement not found");
                    await _unitOfWork.ProjectRequirements.Delete(requirement);
                    results.Add(true);
                }
                await transaction.CommitAsync(cancellationToken);
                return results;
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }

        }
    }
}