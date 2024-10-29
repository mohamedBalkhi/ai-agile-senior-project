
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class AssignMemberDTO
    {
        public Guid ProjectId { get; set; }
        public Guid MemberId { get; set; }
        public PrivilegeLevel MeetingsPrivilegeLevel { get; set; }
        public PrivilegeLevel MembersPrivilegeLevel { get; set; }
        public PrivilegeLevel RequirementsPrivilegeLevel { get; set; }
        public PrivilegeLevel TasksPrivilegeLevel { get; set; }
        public PrivilegeLevel SettingsPrivilegeLevel { get; set; }
    }
}