using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;
namespace Senior.AgileAI.BaseMgt.Application.Features.UserAccount.Queries
{
    public class GetProfileInfromationQuery : IRequest<ProfileDTO>
    {
        public Guid UserId { get; set; }
        public GetProfileInfromationQuery(Guid userId)
        {
            UserId = userId;
        }
    }
}