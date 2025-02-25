using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Management.Queries
{
    public class GetUsersQuery : IRequest<List<UserDTO>>
    {
        public int PageSize { get; set; }
        public int PageNumber { get; set; }
        public GetUsersFilter Filter { get; set; }
    }
}