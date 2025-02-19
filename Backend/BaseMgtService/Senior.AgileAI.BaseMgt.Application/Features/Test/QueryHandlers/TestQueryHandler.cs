using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.Test.Queries;

namespace Senior.AgileAI.BaseMgt.Application.Features.Test.QueryHandlers;

public class TestQueryHandler : IRequestHandler<TestQuery, Unit>
{
    private readonly IUnitOfWork _unitOfWork;
    public TestQueryHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }
    public async Task<Unit> Handle(TestQuery request, CancellationToken cancellationToken)
    {
        if (request.IsTest11)
        {
            Console.WriteLine("Test11");
            return Unit.Value;
        }
        
        try
        {
            // Console.WriteLine("Attempting to get all users from database...");
            var result = await _unitOfWork.Users.GetAllAsync();
            // Console.WriteLine($"Successfully retrieved {result.Count()} users from database.");
            return Unit.Value;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error occurred while getting users: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            throw; // Re-throw the exception to be handled by the global exception handler
        }
    }
}
