public class AddOrgMembersResponseDTO
{
    public List<EmailResult> Results { get; set; } = new();
    public int SuccessCount { get; set; }
    public int FailureCount { get; set; }
}

public class EmailResult
{
    public string Email { get; set; }
    public bool Success { get; set; }
    public string ErrorMessage { get; set; }
}

public static class AddOrgMemberErrors
{
    public const string AlreadyMember = "User is already a member of this organization";
    public const string InvalidEmail = "Invalid email format";
    public const string UserExists = "User already exists in the system";
} 