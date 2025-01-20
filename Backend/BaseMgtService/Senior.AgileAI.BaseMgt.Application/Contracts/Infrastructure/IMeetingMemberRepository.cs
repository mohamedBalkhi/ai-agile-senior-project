using Senior.AgileAI.BaseMgt.Domain.Entities;

namespace Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;

public interface IMeetingMemberRepository : IGenericRepository<MeetingMember>
{
    Task<List<MeetingMember>> GetMeetingMembersAsync(Guid meetingId, CancellationToken cancellationToken = default);
    Task<bool> IsMemberInMeetingAsync(Guid meetingId, Guid organizationMemberId, CancellationToken cancellationToken = default);
    Task<bool> UpdateConfirmationAsync(Guid meetingId, Guid organizationMemberId, bool hasConfirmed, CancellationToken cancellationToken = default);
} 