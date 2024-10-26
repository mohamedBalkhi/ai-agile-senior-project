using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands
{
    public class ChangePasswordCommand : IRequest<bool>
    {
        public ChangePasswordDTO DTO { get; set; }
        public ChangePasswordCommand(ChangePasswordDTO dto)
        {
            DTO = dto;
        }
    }
}