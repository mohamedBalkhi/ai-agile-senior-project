import 'package:agilemeets/core/errors/validation_error.dart';


class ApiResponse<T> {
  final int statusCode;
  final String? message;
  final T? data;
  final List<ValidationError>? validationErrors;

  ApiResponse({
    required this.statusCode,
    this.message,
    this.data,
    this.validationErrors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    // Handle the case where data might be validation errors
    final dynamic rawData = json['data'];
    T? parsedData;
    List<ValidationError>? errors;

    if (json['statusCode'] == 200 && rawData != null) {
      parsedData = fromJson(rawData);
    } else if (rawData is List) {
      errors = rawData
          .map((error) => ValidationError.fromJson(error))
          .where((error) => error.errorMessage.isNotEmpty)
          .toList();
    }

    return ApiResponse<T>(
      statusCode: json['statusCode'],
      message: json['message'],
      data: parsedData,
      validationErrors: errors,
    );
  }
}
