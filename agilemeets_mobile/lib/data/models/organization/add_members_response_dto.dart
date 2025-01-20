class AddMembersResponseDTO {
  final List<EmailResult> results;
  final int successCount;
  final int failureCount;

  AddMembersResponseDTO({
    required this.results,
    required this.successCount,
    required this.failureCount,
  });

  factory AddMembersResponseDTO.fromJson(Map<String, dynamic> json) {
    return AddMembersResponseDTO(
      results: (json['results'] as List)
          .map((e) => EmailResult.fromJson(e))
          .toList(),
      successCount: json['successCount'] as int,
      failureCount: json['failureCount'] as int,
    );
  }
}

class EmailResult {
  final String email;
  final bool success;
  final String? errorMessage;

  EmailResult({
    required this.email,
    required this.success,
    this.errorMessage,
  });

  factory EmailResult.fromJson(Map<String, dynamic> json) {
    return EmailResult(
      email: json['email'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }
} 