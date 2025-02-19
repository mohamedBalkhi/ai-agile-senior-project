using Microsoft.EntityFrameworkCore;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Repositories;

public class MeetingMemberRepository : GenericRepository<MeetingMember>, IMeetingMemberRepository
{
    public MeetingMemberRepository(PostgreSqlAppDbContext context) : base(context)
    {
    }

    public async Task<List<MeetingMember>> GetMeetingMembersAsync(Guid meetingId, CancellationToken cancellationToken = default)
    {
        return await _context.MeetingMembers
            .Include(mm => mm.OrganizationMember)
                .ThenInclude(om => om.User)
            .Where(mm => mm.Meeting_IdMeeting == meetingId)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> IsMemberInMeetingAsync(Guid meetingId, Guid organizationMemberId, CancellationToken cancellationToken = default)
    {
        return await _context.MeetingMembers
            .AnyAsync(mm => mm.Meeting_IdMeeting == meetingId && 
                           mm.OrganizationMember_IdOrganizationMember == organizationMemberId, 
                    cancellationToken);
    }

    public async Task<bool> UpdateConfirmationAsync(Guid meetingId, Guid organizationMemberId, bool hasConfirmed, CancellationToken cancellationToken = default)
    {
        var member = await _context.MeetingMembers
            .FirstOrDefaultAsync(mm => mm.Meeting_IdMeeting == meetingId && 
                                     mm.OrganizationMember_IdOrganizationMember == organizationMemberId, 
                               cancellationToken);

        if (member == null)
            return false;

        member.HasConfirmed = hasConfirmed;
        _context.MeetingMembers.Update(member);
        return true;
    }
} 