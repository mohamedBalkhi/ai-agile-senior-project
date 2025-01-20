using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services.FileParsingStrategy;
#nullable disable
public class CsvFileParserStrategy : IFileParserStrategy
{
    public async Task<List<ProjectRequirement>> ParseFileAsync(Stream fileStream, string fileName)
    {
        using var reader = new StreamReader(fileStream);
        var configuration = new CsvConfiguration(CultureInfo.InvariantCulture)
        {
            HeaderValidated = null,
            MissingFieldFound = null
        };

        using var csv = new CsvReader(reader, configuration);

        // Register custom maps for enum fields
        csv.Context.RegisterClassMap<ProjectRequirementMap>();

        try
        {
            // Convert to list asynchronously
            var records = await Task.Run(() => csv.GetRecords<ProjectRequirementDto>().ToList());
            
            var requirements = records
                .Select(dto => new ProjectRequirement
                {
                    Title = dto.Title,
                    Description = dto.Description,
                    Priority = Enum.Parse<ReqPriority>(dto.Priority, true),
                    Status = Enum.Parse<RequirementsStatus>(dto.Status, true)
                })
                .ToList();

            Console.WriteLine($"Parsed {requirements.Count} requirements");
            foreach (var req in requirements)
            {
                Console.WriteLine($"Title: {req.Title}, Priority: {req.Priority}, Status: {req.Status}");
            }

            return requirements;
        }
        catch (Exception ex)
        {
            throw new Exception($"Error parsing CSV file: {ex.Message}\nStack trace: {ex.StackTrace}");
        }
    }
}

// DTO for CSV mapping
public class ProjectRequirementDto
{
    public string Title { get; set; }
    public string Description { get; set; }
    public string Priority { get; set; }
    public string Status { get; set; }
}

// CSV mapping configuration
public sealed class ProjectRequirementMap : ClassMap<ProjectRequirementDto>
{
    public ProjectRequirementMap()
    {
        Map(m => m.Title).Name("Title");
        Map(m => m.Description).Name("Description");
        Map(m => m.Priority).Name("Priority");
        Map(m => m.Status).Name("Status");
    }
}