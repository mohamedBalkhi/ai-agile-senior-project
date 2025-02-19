using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;


namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class CountryRepository : GenericRepository<Country>, ICountryRepository
{
    public CountryRepository(PostgreSqlAppDbContext context) : base(context)
    {

    }

    public async Task<IEnumerable<Country>> GetActiveCountriesAsync()
    {
        return await _context.Countries.Where(c => c.IsActive == true).ToListAsync();
    }

    // Implement custom methods for Country repository
}