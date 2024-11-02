using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Features.Requirements.Commands;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;



public class AddProjectReqFromFileCommandHandler : IRequestHandler<AddProjectReqFromFileCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IFileParserStrategyFactory _fileParserFactory;

    public AddProjectReqFromFileCommandHandler(
        IUnitOfWork unitOfWork,
        IFileParserStrategyFactory fileParserFactory)
    {
        _unitOfWork = unitOfWork;
        _fileParserFactory = fileParserFactory;
    }

    public async Task<bool> Handle(AddProjectReqFromFileCommand request, CancellationToken cancellationToken)
    {
        string fileExtension = Path.GetExtension(request.FileName);
        var parser = _fileParserFactory.GetStrategy(fileExtension);
        Console.WriteLine(parser.GetType().Name);


        var requirements = await parser.ParseFileAsync(request.FileStream, request.FileName);
        Console.WriteLine("requirementsssssssssssss");
        Console.WriteLine(requirements);
        requirements.ForEach(r => r.Project_IdProject = request.ProjectId);
        // Save to database using unit of work
        await _unitOfWork.ProjectRequirements.AddRangeAsync(requirements);
        await _unitOfWork.CompleteAsync();

        return true; //TODO: Handle file parsing errors
    }
}