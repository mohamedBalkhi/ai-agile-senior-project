import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:equatable/equatable.dart';

/// Base exception class for all application-specific exceptions
abstract class AppException extends Equatable implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];
}

/// Represents validation errors from the API
class ValidationException extends AppException {
  final List<ValidationError> errors;

  const ValidationException(super.message, this.errors, {super.code}) 
    : super(details: errors);

  @override
  List<Object?> get props => [...super.props, errors];
}

/// Represents authentication/authorization errors
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Represents network-related errors
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// Represents server errors (500 range)
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

/// Represents business logic errors
class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.details});
} 