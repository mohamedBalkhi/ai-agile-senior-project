using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

#nullable disable
namespace Senior.AgileAI.BaseMgt.Application.Features.projects.commands
{
    public class AssignMemberCommand : IRequest<bool>
    {
        public AssignMemberDTO Dto { get; set; }
        public Guid UserId { get; set; }
        public AssignMemberCommand(AssignMemberDTO dto, Guid userId)
        {
            Dto = dto;
            UserId = userId;
        }

    }
}