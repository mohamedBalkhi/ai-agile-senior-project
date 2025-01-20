import 'package:agilemeets/widgets/error_handlers/error_view.dart';
import 'package:flutter/material.dart';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/widgets/error_handlers/error_snackbar.dart';

extension BuildContextExtensions on BuildContext {
  void showErrorSnackbar(
    AppException error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      ErrorSnackbar(
        error: error,
        onRetry: onRetry,
      ),
    );
  }

  void showErrorDialog(
    AppException error, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        content: ErrorView(
          error: error,
          onRetry: onRetry,
        ),
      ),
    );
  }
} 