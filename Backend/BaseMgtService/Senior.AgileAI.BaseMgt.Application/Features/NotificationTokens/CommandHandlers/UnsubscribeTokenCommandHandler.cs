using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.Commands;

namespace Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.CommandHandlers;

public class UnsubscribeTokenCommandHandler : IRequestHandler<UnsubscribeTokenCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;

    public UnsubscribeTokenCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<bool> Handle(UnsubscribeTokenCommand request, CancellationToken cancellationToken)
    {
        var result = await _unitOfWork.NotificationTokens
            .DeleteToken(request.Dto.Token, request.Dto.DeviceId, cancellationToken);

        if (result)
        {
            await _unitOfWork.CompleteAsync();
        }

        return result;
    }
} 