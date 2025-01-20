import 'package:flutter/material.dart';
import 'package:agilemeets/core/errors/validation_error.dart';

class FormValidationErrors extends StatelessWidget {
  final List<ValidationError> errors;
  final String? fieldName;

  const FormValidationErrors({
    super.key,
    required this.errors,
    this.fieldName,
  });

  @override
  Widget build(BuildContext context) {
    final fieldErrors = fieldName != null
        ? errors.where((e) => e.propertyName.toLowerCase().contains(fieldName!.toLowerCase()))
        : errors;

    if (fieldErrors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fieldErrors.map((error) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          error.errorMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      )).toList(),
    );
  }
} 