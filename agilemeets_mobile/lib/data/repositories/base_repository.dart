import 'dart:developer' as developer;
import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

abstract class BaseRepository {
  final ApiClient _apiClient = ApiClient();
  
  ApiClient get apiClient => _apiClient;

  /// Safely executes an API call with proper error handling
  Future<T> safeApiCall<T>({
    required Future<T> Function() call,
    String? context,
  }) async {
    try {
      return await call();
    } on DioException catch (e) {
      // Don't trigger auth check for validation/auth errors
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      rethrow;
    } catch (e, stackTrace) {
      final errorContext = context != null ? ' in $context' : '';
      developer.log(
        'Unexpected error$errorContext: $e',
        name: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      
      throw ServerException(
        'An unexpected error occurred',
        code: 'UNEXPECTED_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Handles API response with proper error mapping
  T handleResponse<T>({
    required dynamic response,
    required T Function(dynamic) onSuccess,
    String? context,
  }) {
    try {
      if (response == null) {
        throw const BusinessException(
          'Empty response received',
          code: 'EMPTY_RESPONSE',
        );
      }

      // Check if response has error structure
      if (response is Map<String, dynamic> && 
          (response.containsKey('error') && response['error'] != null || 
           response.containsKey('errors') && response['errors'] != null)) {
        final message = response['message'] ?? 'Operation failed';
        throw BusinessException(
          message,
          code: 'OPERATION_FAILED',
          details: response,
        );
      }

      return onSuccess(response);
    } catch (e, stackTrace) {
      final errorContext = context != null ? ' in $context' : '';
      developer.log(
        'Error handling response$errorContext: $e',
        name: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      
      if (e is AppException) {
        rethrow;
      }
      
      throw ServerException(
        'Failed to process response',
        code: 'RESPONSE_PROCESSING_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Validates input parameters
  void validateParams(Map<String, dynamic> params) {
    final errors = <ValidationError>[];

    params.forEach((key, value) {
      if (value == null || (value is String && value.isEmpty)) {
        errors.add(
          ValidationError(
            propertyName: key,
            errorMessage: '$key is required',
            errorCode: 'REQUIRED',
          ),
        );
      }
    });

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Validation failed',
        errors,
        code: 'VALIDATION_ERROR',
      );
    }
  }

  /// Logs repository operations with consistent format
  void logOperation(String operation, {
    Map<String, dynamic>? params,
    String? error,
    StackTrace? stackTrace,
  }) {
    final message = StringBuffer('$operation');
    if (params != null) {
      message.write(' with params: $params');
    }
    if (error != null) {
      message.write(' failed: $error');
    }

    developer.log(
      message.toString(),
      name: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
