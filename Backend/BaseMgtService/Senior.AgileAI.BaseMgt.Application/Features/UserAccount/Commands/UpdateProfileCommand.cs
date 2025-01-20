using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;
#nullable disable
namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Commands
{
    public class UpdateProfileCommand : IRequest<Guid>
    {
        public updateProfileDTO DTO { get; set; }
        public Guid UserId { get; set; }
        public UpdateProfileCommand(updateProfileDTO dto, Guid userId)
        {
            DTO = dto;
            UserId = userId;
        }



    }
}