using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands
{
    public class CompleteProfileCommand : IRequest<bool>
    {
        public CompleteProfileDTO Dto { get; set; }
        public Guid UserId { get; set; } // from the token, because first the user will login and then complete the profile.

        public CompleteProfileCommand(CompleteProfileDTO dto, Guid userId)
        {
            Dto = dto;
            UserId = userId;
        }
    }
}