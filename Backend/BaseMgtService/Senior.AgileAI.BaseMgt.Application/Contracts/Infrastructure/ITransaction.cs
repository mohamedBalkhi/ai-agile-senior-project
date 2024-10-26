namespace Senior.AgileAI.BaseMgt.Application.Contracts.infrastructure;

public interface ITransaction : IDisposable
{
    Task CommitAsync(CancellationToken cancellationToken = default);
    Task RollbackAsync(CancellationToken cancellationToken = default);
}
