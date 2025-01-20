class AuthResult {
  final String? accessToken;
  // Remove refreshToken since it's handled by HttpOnly cookie

  AuthResult({this.accessToken});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
    };
  }

  @override
  String toString() {
    return 'AuthResult(accessToken: $accessToken)';
  }
}
