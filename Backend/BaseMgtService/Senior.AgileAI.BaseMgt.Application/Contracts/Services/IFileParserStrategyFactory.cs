namespace Senior.AgileAI.BaseMgt.Application.Contracts.Services
{
    public interface IFileParserStrategyFactory
    {
        IFileParserStrategy GetStrategy(string fileExtension);
    }
}
