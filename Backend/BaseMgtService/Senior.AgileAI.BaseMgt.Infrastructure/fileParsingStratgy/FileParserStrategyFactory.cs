using Senior.AgileAI.BaseMgt.Application.Contracts.Services;

public class FileParserStrategyFactory : IFileParserStrategyFactory
{
    public IFileParserStrategy GetStrategy(string fileExtension)
    {
        return fileExtension.ToLower() switch
        {
            ".csv" => new CsvFileParserStrategy(),
            ".xlsx" => new ExcelFileParserStrategy(),
            _ => throw new NotSupportedException($"File type {fileExtension} is not supported")
        };
    }
}
