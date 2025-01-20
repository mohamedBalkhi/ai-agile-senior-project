import 'package:agilemeets/core/errors/validation_error.dart';


class ValidationException implements Exception {
  final List<ValidationError> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    return 'ValidationException: ${errors.map((e) => '${e.propertyName}: ${e.errorMessage}').join(', ')}';
  }
}
