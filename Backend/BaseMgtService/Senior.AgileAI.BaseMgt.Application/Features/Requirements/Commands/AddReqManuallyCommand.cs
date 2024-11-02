using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands
{
    public class AddReqManuallyCommand : IRequest<bool>
    {
        public AddReqManuallyDTO DTO { get; set; }
        public AddReqManuallyCommand(AddReqManuallyDTO dto)
        {
            DTO = dto;
        }
    }
}