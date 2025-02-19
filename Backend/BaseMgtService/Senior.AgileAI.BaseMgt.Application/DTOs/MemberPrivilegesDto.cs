namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class MemberPrivilegesDto
    {
        public required string  MeetingsPrivilegeLevel { get; set; }
        public required string MembersPrivilegeLevel { get; set; }
        public required string RequirementsPrivilegeLevel { get; set; }
        public required string TasksPrivilegeLevel { get; set; }
        public required string SettingsPrivilegeLevel { get; set; }
    }
}