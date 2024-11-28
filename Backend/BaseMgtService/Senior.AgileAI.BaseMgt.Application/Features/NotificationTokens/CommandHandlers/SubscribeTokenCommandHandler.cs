using MediatR;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.Commands;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using System.ComponentModel.DataAnnotations;

namespace Senior.AgileAI.BaseMgt.Application.Features.NotificationTokens.CommandHandlers;

public class SubscribeTokenCommandHandler : IRequestHandler<SubscribeTokenCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private const int MaxTokensPerUser = 5;

    public SubscribeTokenCommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<bool> Handle(SubscribeTokenCommand request, CancellationToken cancellationToken)
    {
        // Validate token format
        if (!await _unitOfWork.NotificationTokens.ValidateTokenFormat(request.Dto.Token))
        {
            throw new ValidationException("Invalid token format");
        }

        var existingToken = await _unitOfWork.NotificationTokens
            .GetByTokenAndDeviceId(request.Dto.Token, request.Dto.DeviceId, cancellationToken);

        if (existingToken != null)
        {
            return true; // Token already exists
        }

        // Check token limit per user
        var userTokenCount = await _unitOfWork.NotificationTokens
            .GetUserTokenCount(request.UserId, cancellationToken);

        if (userTokenCount >= MaxTokensPerUser)
        {
            throw new ValidationException($"Maximum number of tokens ({MaxTokensPerUser}) reached for this user");
        }

        var notificationToken = new NotificationToken
        {
            Token = request.Dto.Token,
            DeviceId = request.Dto.DeviceId,
            User_IdUser = request.UserId
        };

        await _unitOfWork.NotificationTokens.AddAsync(notificationToken);
        await _unitOfWork.CompleteAsync();

        return true;
    }
} 