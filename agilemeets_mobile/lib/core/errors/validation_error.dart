import 'package:equatable/equatable.dart';

/// Represents a single validation error from the API
class ValidationError extends Equatable {
  final String propertyName;
  final String errorMessage;
  final String? errorCode;
  final dynamic attemptedValue;
  final Map<String, dynamic>? customState;

  const ValidationError({
    required this.propertyName,
    required this.errorMessage,
    this.errorCode,
    this.attemptedValue,
    this.customState,
  });

  /// Creates a ValidationError from JSON
  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      propertyName: json['propertyName'] as String,
      errorMessage: json['errorMessage'] as String,
      errorCode: json['errorCode'] as String?,
      attemptedValue: json['attemptedValue'],
      customState: json['customState'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
    propertyName,
    errorMessage,
    errorCode,
    attemptedValue,
    customState,
  ];
} 