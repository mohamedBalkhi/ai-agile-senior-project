class AudioUrlResponse {
  final String preSignedUrl;
  final String fileName;
  final String contentType;
  final int expirationMinutes;

  AudioUrlResponse({
    required this.preSignedUrl,
    required this.fileName,
    required this.contentType,
    required this.expirationMinutes,
  });

  factory AudioUrlResponse.fromJson(Map<String, dynamic> json) {
    return AudioUrlResponse(
      preSignedUrl: json['preSignedUrl'] as String,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      expirationMinutes: json['expirationMinutes'] as int,
    );
  }
} 