class JoinMeetingResponse {
  final String token;
  final String serverUrl;

  JoinMeetingResponse({
    required this.token,
    required this.serverUrl,
  });

  factory JoinMeetingResponse.fromJson(Map<String, dynamic> json) {
    return JoinMeetingResponse(
      token: json['token'] as String,
      serverUrl: json['serverUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'serverUrl': serverUrl,
    };
  }
} 