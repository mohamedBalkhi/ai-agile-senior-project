import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/auth/auth_state.dart';
import 'dart:developer' as developer;

class AuthNavigationService {
  static void handleAuthState(
    BuildContext context, {
    required AuthStatus status,
    required bool isInSignupFlow,
    required bool hasSeenOnboarding,
  }) {
    // Only skip navigation during loading state
    if (status == AuthStatus.loading) {
      developer.log(
        'Skipping navigation during loading state',
        name: 'AuthNavigation'
      );
      return;
    }

    developer.log(
      'Handling navigation for status: $status (signup: $isInSignupFlow)',
      name: 'AuthNavigation'
    );

    final String route = _determineRoute(
      status: status,
      isInSignupFlow: isInSignupFlow,
      hasSeenOnboarding: hasSeenOnboarding,
    );

    developer.log(
      'Navigating to $route (status: $status, signup: $isInSignupFlow)',
      name: 'AuthNavigation'
    );
    
    if (route == '/reset-password') {
      Navigator.of(context).pushReplacementNamed(route, arguments: context.read<AuthCubit>().state.userEmail);
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  static String _determineRoute({
    required AuthStatus status,
    required bool isInSignupFlow,
    required bool hasSeenOnboarding,
  }) {

    // Handle signup flow states first
    if (isInSignupFlow) {
      return switch (status) {
        AuthStatus.emailVerificationRequired => '/email-verification',
        AuthStatus.organizationCreationRequired => '/create-organization',
        AuthStatus.profileCompletionRequired => '/complete-profile',
        AuthStatus.authenticated => '/shell',
        _ => '/login',
      };
    }

    // Handle regular auth flow
    return switch (status) {
      AuthStatus.unauthenticated => hasSeenOnboarding ? '/login' : '/onboarding',
      AuthStatus.emailVerificationRequired => '/email-verification',
      AuthStatus.organizationCreationRequired => '/create-organization',
      AuthStatus.profileCompletionRequired => '/complete-profile',
      AuthStatus.authenticated => '/shell',
      AuthStatus.loading => '/',
      AuthStatus.resetCodeSent => '/reset-password',
      _ => '/login',
    };
  }

  static bool shouldHandleNavigation(AuthStatus status, bool isInSignupFlow) {
    // Always handle navigation for these states regardless of signup flow
    final criticalStates = [
      AuthStatus.organizationCreationRequired,
      AuthStatus.profileCompletionRequired,
      AuthStatus.authenticated,
      AuthStatus.resetCodeSent,
    ];

    if (criticalStates.contains(status)) return true;

    // Don't handle navigation for other states during signup flow
    if (isInSignupFlow) return false;
    
    // Handle navigation for these states in regular flow
    final regularStates = [
      AuthStatus.unauthenticated,
      AuthStatus.emailVerificationRequired,
    ];

    return regularStates.contains(status);
  }
} 