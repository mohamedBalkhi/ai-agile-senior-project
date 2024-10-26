using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using Senior.AgileAI.BaseMgt.Application.Features.Country.Queries;

namespace Senior.AgileAI.BaseMgt.Application.Features.Country.QueriesHandlers
{
    public class GetAllCountriesQueryHandler : IRequestHandler<GetAllCountriesQuery, List<CountryDTO>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public GetAllCountriesQueryHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<List<CountryDTO>> Handle(GetAllCountriesQuery request, CancellationToken cancellationToken)
        {
            var countries = await _unitOfWork.Countries
                .GetActiveCountriesAsync();  // or whatever your enum/status field is named

            return countries.Select(c => new CountryDTO
            {
                Id = c.Id,
                Name = c.Name,
                Code = c.Code
            }).ToList();
        }
    }
}
