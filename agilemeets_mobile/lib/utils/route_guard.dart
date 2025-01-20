import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../services/auth_navigation_service.dart';
import "dart:developer" as developer;

class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<AuthStatus> primaryStates;
  final List<AuthStatus> secondaryStates;
  final String redirectRoute;

  const RouteGuard({
    super.key,
    required this.child,
    required this.primaryStates,
    this.secondaryStates = const [
      AuthStatus.loading,
      AuthStatus.error,
      AuthStatus.validationError
    ],
    required this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        final allowedStates = [...primaryStates, ...secondaryStates];
        
        developer.log(
          'RouteGuard: current=${state.status}, allowed=$allowedStates', 
          name: 'RouteGuard'
        );
        bool shouldHandle = AuthNavigationService.shouldHandleNavigation(state.status, state.isInSignupFlow);
        developer.log(
          'RouteGuard: shouldHandle=$shouldHandle',
          name: 'RouteGuard'
        );


        if (shouldHandle && !allowedStates.contains(state.status)) {
          developer.log(
            'RouteGuard: pushing redirectRoute=$redirectRoute',
            name: 'RouteGuard'
          );
          Navigator.of(context).pushReplacementNamed(redirectRoute);
        }
      },
      child: child,
    );
  }
} 