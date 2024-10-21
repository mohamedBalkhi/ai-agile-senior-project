using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Test.Queries;

public record TestQuery(bool IsTest11 = false) : IRequest<Unit>; 