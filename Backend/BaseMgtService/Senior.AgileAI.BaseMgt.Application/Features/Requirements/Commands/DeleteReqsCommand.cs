
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands
{
#nullable disable
    public class DeleteReqsCommand : IRequest<List<bool>>
    {
        public List<Guid> RequirementIds { get; set; } //from body..

        public DeleteReqsCommand(List<Guid> requirementIds)
        {
            RequirementIds = requirementIds;
        }
    }
}