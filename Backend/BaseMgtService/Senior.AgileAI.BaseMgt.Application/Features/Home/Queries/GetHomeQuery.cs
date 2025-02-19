using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Home.Queries;

public class GetHomeQuery : IRequest<HomeDTO>
{
    public Guid UserId { get; set; }
}