using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands
{
    public class VerifyEmailCommand : IRequest<bool>
    {
        public VerifyEmailDTO DTO { get; set; }
        public VerifyEmailCommand(VerifyEmailDTO dto)
        {
            DTO = dto;
        }
    }
}