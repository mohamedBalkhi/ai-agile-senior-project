using OfficeOpenXml;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Services.FileParsingStrategy;
public class ExcelFileParserStrategy : IFileParserStrategy
{
    public async Task<List<ProjectRequirement>> ParseFileAsync(Stream fileStream, string fileName)
    {
        Console.WriteLine("excel file parser strategy");
        // Set EPPlus license context
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

        using var package = await Task.Run(() => new ExcelPackage(fileStream));
        var worksheet = package.Workbook.Worksheets[0]; // First worksheet
        var requirements = new List<ProjectRequirement>();
        try
        {
            await Task.Run(() =>
            {
                // Get row count
                int rowCount = worksheet.Dimension?.Rows ?? 0;
                Console.WriteLine(rowCount);

                // Start from row 2 (assuming row 1 is header)
                for (int row = 2; row <= rowCount; row++)
                {
                    var title = worksheet.Cells[row, 1].Text;
                    var description = worksheet.Cells[row, 2].Text;
                    var priorityStr = worksheet.Cells[row, 3].Text;
                    var statusStr = worksheet.Cells[row, 4].Text;

                    // Skip empty rows
                    if (string.IsNullOrWhiteSpace(title)) continue;

                    // Parse enums
                    var (priority, status) = ValidateAndParseEnums(priorityStr, statusStr, row);

                    requirements.Add(new ProjectRequirement
                    {
                        Title = title,
                        Description = description,
                        Priority = priority,
                        Status = status
                    });
                }
            });

            return requirements;
        }
        catch (Exception ex)
        {
            throw new Exception($"Error parsing Excel file: {ex.Message}");
        }
    }

    private (ReqPriority priority, RequirementsStatus status) ValidateAndParseEnums(string priorityStr, string statusStr, int row)
    {
        // Define valid values
        var validPriorities = Enum.GetNames(typeof(ReqPriority));
        var validStatuses = Enum.GetNames(typeof(RequirementsStatus));

        // Validate Priority
        if (!Enum.TryParse<ReqPriority>(priorityStr, true, out var priority))
        {
            throw new Exception(
                $"Invalid priority value '{priorityStr}' at row {row}. " +
                $"Valid values are: {string.Join(", ", validPriorities)}"
            );
        }

        // Validate Status
        if (!Enum.TryParse<RequirementsStatus>(statusStr, true, out var status))
        {
            throw new Exception(
                $"Invalid status value '{statusStr}' at row {row}. " +
                $"Valid values are: {string.Join(", ", validStatuses)}"
            );
        }
        return (priority, status);
    }
}