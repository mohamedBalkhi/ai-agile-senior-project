using Senior.AgileAI.BaseMgt.Domain.Entities;


namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services
{
    public interface IFileParserStrategy
    {
        Task<List<ProjectRequirement>> ParseFileAsync(Stream fileStream, string fileName);
    }
}