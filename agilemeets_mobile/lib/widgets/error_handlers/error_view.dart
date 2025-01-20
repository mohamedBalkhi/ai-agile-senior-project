import 'package:flutter/material.dart';
import 'package:agilemeets/core/errors/app_exception.dart';

class ErrorView extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (error) {
      ValidationException() => _ValidationErrorView(
          error: error as ValidationException,
          onRetry: onRetry,
        ),
      NetworkException() => _NetworkErrorView(
          error: error as NetworkException,
          onRetry: onRetry,
        ),
      AuthException() => _AuthErrorView(
          error: error as AuthException,
          onRetry: onRetry,
        ),
      _ => _GenericErrorView(
          error: error,
          onRetry: onRetry,
        ),
    };
  }
}

class _ValidationErrorView extends StatelessWidget {
  final ValidationException error;
  final VoidCallback? onRetry;

  const _ValidationErrorView({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          error.message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ...error.errors.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${e.errorMessage}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ],
    );
  }
}

class _NetworkErrorView extends StatelessWidget {
  final NetworkException error;
  final VoidCallback? onRetry;

  const _NetworkErrorView({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wifi_off,
          color: Colors.orange,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          error.message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}

class _AuthErrorView extends StatelessWidget {
  final AuthException error;
  final VoidCallback? onRetry;

  const _AuthErrorView({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          error.message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ],
    );
  }
}

class _GenericErrorView extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;

  const _GenericErrorView({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          error.message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ],
    );
  }
} 