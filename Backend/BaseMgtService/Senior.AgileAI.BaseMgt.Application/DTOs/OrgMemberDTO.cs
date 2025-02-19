namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class AddOrgMembersDTO
    {
        public required List<string> Emails { get; set; }  //? only emails is needed all other info will be default.

    }
}