class ForgotPasswordDTO {
  final String userId;
  final String newPassword;

  ForgotPasswordDTO({
    required this.userId,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'newPassword': newPassword,
    };
  }
}
