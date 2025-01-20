class GuidApiResponse {
  final int statusCode;
  final String? message;
  final String data;

  GuidApiResponse({
    required this.statusCode,
    this.message,
    required this.data,
  });

  factory GuidApiResponse.fromJson(Map<String, dynamic> json) {
    return GuidApiResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String?,
      data: json['data'] as String,
    );
  }
}

class BooleanApiResponse {
  final int statusCode;
  final String? message;
  final bool data;

  BooleanApiResponse({
    required this.statusCode,
    this.message,
    required this.data,
  });

  factory BooleanApiResponse.fromJson(Map<String, dynamic> json) {
    return BooleanApiResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String?,
      data: json['data'] as bool,
    );
  }
} 