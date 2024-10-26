using MediatR;
using Senior.AgileAI.BaseMgt.Application.DTOs;

namespace Senior.AgileAI.BaseMgt.Application.Features.Country.Queries
{
    public class GetAllCountriesQuery : IRequest<List<CountryDTO>>
    {

    }
}