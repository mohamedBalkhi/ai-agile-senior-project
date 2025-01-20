import 'package:flutter/material.dart';
import 'package:agilemeets/core/errors/app_exception.dart';

class ErrorSnackbar extends SnackBar {
  ErrorSnackbar({
    super.key,
    required AppException error,
    VoidCallback? onRetry,
  }) : super(
          content: Row(
            children: [
              Icon(
                _getIcon(error),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error.message),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'RETRY',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          backgroundColor: _getColor(error),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        );

  static IconData _getIcon(AppException error) {
    return switch (error) {
      ValidationException() => Icons.error_outline,
      NetworkException() => Icons.wifi_off,
      AuthException() => Icons.lock_outline,
      _ => Icons.error_outline,
    };
  }

  static Color _getColor(AppException error) {
    return switch (error) {
      ValidationException() => Colors.red,
      NetworkException() => Colors.orange,
      AuthException() => Colors.red.shade700,
      _ => Colors.red,
    };
  }
} 