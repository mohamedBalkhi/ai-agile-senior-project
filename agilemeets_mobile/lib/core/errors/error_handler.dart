import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import 'app_exception.dart';
import 'validation_error.dart';

/// Handles conversion of various error types to AppException
class ErrorHandler {
  /// Converts a DioException to an appropriate AppException
  static AppException handleDioException(DioException error) {
    developer.log(
      'API Error: ${error.message}',
      name: 'ErrorHandler',
      error: error,
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response!);

      case DioExceptionType.cancel:
        return const NetworkException(
          'Request cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'Connection error. Please check your internet connection.',
          code: 'NO_CONNECTION',
        );

      default:
        return NetworkException(
          'Network error occurred',
          code: 'NETWORK_ERROR',
          details: error.message,
        );
    }
  }

  /// Handles HTTP error responses
  static AppException _handleBadResponse(Response response) {
    final data = response.data;
    
    switch (response.statusCode) {
      case 400:
        if (data is Map<String, dynamic>) {
          if (data['errors'] != null) {
            final errors = (data['errors'] as List)
                .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
                .toList();
            return ValidationException(
              data['message'] ?? 'Validation failed',
              errors,
              code: 'VALIDATION_ERROR',
            );
          } else if (data['error'] != null || data['message'] != null) {
            return BusinessException(
              data['message'] ?? data['error'] ?? 'Bad request',
              code: 'BAD_REQUEST',
              details: data,
            );
          }
        }
        return BusinessException(
          'Invalid request',
          code: 'BAD_REQUEST',
          details: data,
        );

      case 401:
        return AuthException(
          data['message'] ?? 'Unauthorized',
          code: 'UNAUTHORIZED',
          details: data,
        );

      case 403:
        return AuthException(
          data['message'] ?? 'Forbidden',
          code: 'FORBIDDEN',
          details: data,
        );

      case 404:
        return BusinessException(
          data['message'] ?? 'Resource not found',
          code: 'NOT_FOUND',
          details: data,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          data['message'] ?? 'Server error',
          code: 'SERVER_ERROR',
          details: data,
        );

      default:
        return BusinessException(
          data['message'] ?? 'Unknown error occurred',
          code: 'UNKNOWN',
          details: data,
        );
    }
  }
} 