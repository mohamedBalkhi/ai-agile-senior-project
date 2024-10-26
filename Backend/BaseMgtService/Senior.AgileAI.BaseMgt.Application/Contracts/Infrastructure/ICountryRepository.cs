using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface ICountryRepository : IGenericRepository<Country> {
    Task<IEnumerable<Country>> GetActiveCountriesAsync();
    // ? Custom methods for Country repository
}
