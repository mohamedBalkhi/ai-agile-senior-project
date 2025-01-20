class NotificationTokenDTO {
  final String token;
  final String deviceId;

  NotificationTokenDTO({
    required this.token,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'deviceId': deviceId,
  };
} 