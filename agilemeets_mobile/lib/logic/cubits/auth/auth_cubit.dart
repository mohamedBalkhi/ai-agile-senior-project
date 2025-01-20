import 'dart:async';
import 'dart:developer' as developer;

import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/data/models/forgot_password_dto.dart';
import 'package:agilemeets/utils/auth_event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/sign_up_dto.dart';
import 'auth_state.dart';
import '../../../models/decoded_token.dart';
import 'package:agilemeets/utils/secure_storage.dart';
import 'package:agilemeets/data/api/api_client.dart';
import 'package:agilemeets/services/notification_service.dart';

// Hide the old ValidationException to avoid conflicts
// import '../../../data/exceptions/validation_exception.dart' hide ValidationException;

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final NotificationService _notificationService = NotificationService();
  late StreamSubscription<AuthenticationEvent> _authEventSubscription;
  bool _isInSignupFlow = false;
  bool _isCheckingStatus = false;

  AuthCubit(this._authRepository) : super(AuthState.initial()) {
    _authEventSubscription = authEventBus.stream.listen((event) {
      if (event == AuthenticationEvent.unauthorized) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    });
  }

  @override
  Future<void> close() {
    _authEventSubscription.cancel();
    return super.close();
  }

  Future<AuthStatus> _determineAuthStatus(DecodedToken token) async {
    if (!token.isTrusted) {
      await _authRepository.resendCode(token.userId);
      return AuthStatus.emailVerificationRequired;
    }
    if (token.isAdmin && !token.isActive) {
      return AuthStatus.organizationCreationRequired;
    }
    
    if (!token.isAdmin && !token.isActive) {
      return AuthStatus.profileCompletionRequired;
    }
    
    return AuthStatus.authenticated;
  }

  Future<void> checkAuthStatus() async {
    if (_isCheckingStatus) return;
    
    try {
      _isCheckingStatus = true;
      
      // Don't check auth during error states
      if (state.status == AuthStatus.error || 
          state.status == AuthStatus.validationError) {
        return;
      }

      // Skip check during signup flow verification
      if (state.status == AuthStatus.emailVerificationRequired && 
          state.isInSignupFlow) {
        developer.log(
          'Re-emitting state - in signup flow verification',
          name: 'AuthCubit'
        );
        emit(state.copyWith(
          status: AuthStatus.emailVerificationRequired,
          isInSignupFlow: true,
        ));
        return;
      }
      
      // If we're already unauthenticated, re-emit the state to trigger navigation
      if (state.status == AuthStatus.unauthenticated && !state.isInSignupFlow) {
        developer.log(
          'Already unauthenticated, re-emitting state',
          name: 'AuthCubit'
        );
        emit(state.copyWith(status: AuthStatus.loading));
        emit(AuthState.initial().copyWith(
          status: AuthStatus.unauthenticated,
          isInSignupFlow: false,
        ));
        return;
      }
      
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (!isLoggedIn) {
        emit(AuthState.initial().copyWith(
          status: AuthStatus.unauthenticated,
          isInSignupFlow: false,
        ));
        return;
      }
      
      developer.log(
        'Checking auth status (previous: ${state.status})',
        name: 'AuthCubit'
      );
      
      final token = await SecureStorage.getToken('access_token');
      if (token == null) {
        developer.log('No token found', name: 'AuthCubit');
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          isInSignupFlow: false,
        ));
        return;
      }

      emit(state.copyWith(status: AuthStatus.loading));
      
      final newToken = await ApiClient().refreshToken();
      if (newToken != null) {
        final newDecodedToken = DecodedToken.fromJwt(newToken);
        final nextStatus = await _determineAuthStatus(newDecodedToken);
        
        developer.log(
          'Auth status determined: $nextStatus',
          name: 'AuthCubit'
        );
        
        emit(state.copyWith(
          status: nextStatus,
          decodedToken: newDecodedToken,
          isAdmin: newDecodedToken.isAdmin,
          isTrusted: newDecodedToken.isTrusted,
          isActive: newDecodedToken.isActive,
          isInSignupFlow: false,
        ));
      } else {
        await SecureStorage.deleteAllTokens();
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          isInSignupFlow: false,
        ));
      }
    } catch (e) {
      developer.log(
        'Error checking auth status: $e',
        name: 'AuthCubit',
        error: e,
      );
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: null,
        isInSignupFlow: false,
      ));
    } finally {
      _isCheckingStatus = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(state.copyWith(
        status: AuthStatus.loading,
        error: null,
        validationErrors: null,
      ));

      final result = await _authRepository.login(email, password);
      final decodedToken = DecodedToken.fromJwt(result.accessToken!);

      // Determine next status without emitting intermediate states
      final nextStatus = await _determineAuthStatus(decodedToken);
      final notificationSuccess = await _notificationService.subscribe();
      if (!notificationSuccess) {
        developer.log(
          'Failed to subscribe to notifications',
          name: 'AuthCubit',
        );
      }
      // Emit final state with correct status
      emit(state.copyWith(
        status: nextStatus,
        decodedToken: decodedToken,
        userId: decodedToken.userId,
        email: decodedToken.email,
        isAdmin: decodedToken.isAdmin,
        isTrusted: decodedToken.isTrusted,
        isActive: decodedToken.isActive,
        error: null,
        validationErrors: null,
      ));

    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.validationError,
        validationErrors: e.errors,
        error: null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.message,
        validationErrors: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: 'An unexpected error occurred',
        validationErrors: null,
      ));
    }
  }

    Future<void> signUp(SignUpDTO signUpDTO) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      error: null,
      validationErrors: null,
      isInSignupFlow: true,
    ));
    
    try {
      _isInSignupFlow = true;
      final signUpResponse = await _authRepository.signUp(signUpDTO);
      
      developer.log(
        'Signup successful, transitioning to email verification',
        name: 'AuthCubit'
      );
      
      emit(state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        userId: signUpResponse.userId,
        email: signUpDTO.email,
        password: signUpDTO.password,
        error: null,
        validationErrors: null,
        isInSignupFlow: true,
      ));

    } catch (e) {
      _isInSignupFlow = false;
      if (e is ValidationException) {
        emit(state.copyWith(
          status: AuthStatus.validationError,
          validationErrors: e.errors,
          error: null,
          isInSignupFlow: false,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          error: e.toString(),
          validationErrors: null,
          isInSignupFlow: false,
        ));
      }
    }
  }

  Future<void> verifyEmail(String code) async {
    if (state.userIdentifier == null) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: 'Missing user information',
      ));
      return;
    }

    try {
      emit(state.copyWith(
        status: AuthStatus.loading,
        error: null,
        validationErrors: null,
      ));
      
      final success = await _authRepository.verifyEmail(code, state.userIdentifier!);
      if (success) {
        if (_isInSignupFlow && state.userEmail != null && state.password != null) {
          developer.log(
            'Email verified in signup flow, attempting login',
            name: 'AuthCubit'
          );
          
          final loginResult = await _authRepository.login(state.userEmail!, state.password!);
          final decodedToken = DecodedToken.fromJwt(loginResult.accessToken!);
          
          developer.log(
            'Login successful, transitioning to organization creation',
            name: 'AuthCubit'
          );
          
          emit(state.copyWith(
            status: AuthStatus.organizationCreationRequired,
            authResult: loginResult,
            decodedToken: decodedToken,
            isInSignupFlow: true,
            isAdmin: decodedToken.isAdmin,
            isTrusted: true,
            isActive: decodedToken.isActive,
          ));
        } else {
          developer.log(
            'Email verified outside signup flow, checking auth status',
            name: 'AuthCubit'
          );
          await checkAuthStatus();
        }
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          error: 'Invalid verification code',
        ));
      }
    } catch (e) {
      developer.log(
        'Error during email verification: $e',
        name: 'AuthCubit',
        error: e,
      );
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> resendVerificationCode() async {
    if (state.userIdentifier == null || state.userEmail == null) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: 'Missing user information',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final success = await _authRepository.resendCode(state.userIdentifier!);
      if (success.isNotEmpty) {
        emit(state.copyWith(status: AuthStatus.emailVerificationRequired));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error, 
          error: 'Failed to resend verification code'
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> logout() async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      
      // Unsubscribe from notifications before logout
      _isInSignupFlow = false;
      await _notificationService.unsubscribe();
      
      await _authRepository.logout();
      emit(state.copyWith(status: AuthStatus.unauthenticated, isInSignupFlow: false));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> requestPasswordReset(String email) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final userId = await _authRepository.requestPasswordReset(email);
      emit(state.copyWith(
        status: AuthStatus.resetCodeSent,
        userId: userId,  // Store the userId
        email: email,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> verifyResetCode(String code) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final success = await _authRepository.verifyEmail(code, state.userId!);
      if (success) {
        emit(state.copyWith(status: AuthStatus.resetCodeVerified));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          error: 'Invalid verification code',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> resetPassword(String newPassword) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final dto = ForgotPasswordDTO(
        userId: state.userId!,
        newPassword: newPassword,
      );
      final success = await _authRepository.forgotPassword(dto);
      if (success) {
        emit(state.copyWith(status: AuthStatus.passwordResetSuccess));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          error: 'Password reset failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> handleStateTransition(AuthStatus newStatus) async {
    try {
      final newToken = await ApiClient().refreshToken();
      
      if (newToken != null) {
        final decodedToken = DecodedToken.fromJwt(newToken);
        final nextStatus = await _determineAuthStatus(decodedToken);
        
        if (nextStatus == newStatus) {
          emit(state.copyWith(
            status: nextStatus,
            decodedToken: decodedToken,
            isAdmin: decodedToken.isAdmin,
            isTrusted: decodedToken.isTrusted,
            isActive: decodedToken.isActive,
          ));
        } else {
          developer.log(
            'Unexpected state transition: Expected $newStatus, got $nextStatus',
            name: 'AuthCubit',
          );
          emit(state.copyWith(
            status: nextStatus,
            decodedToken: decodedToken,
            isAdmin: decodedToken.isAdmin,
            isTrusted: decodedToken.isTrusted,
            isActive: decodedToken.isActive,
          ));
        }
      } else {
        throw Exception('Failed to refresh token during state transition');
      }
    } catch (e) {
      developer.log(
        'Error during state transition: $e',
        name: 'AuthCubit',
        error: e,
      );
      emit(state.copyWith(
        status: AuthStatus.error,
        error: 'Failed to process your request. Please try again.',
      ));
    }
  }

  // Helper method to clear signup flow and errors
  void _clearSignupFlow() {
    _isInSignupFlow = false;
    emit(state.copyWith(
      error: null,
      validationErrors: null,
      isInSignupFlow: false,
    ));
  }

  void clearErrors() {
    emit(state.copyWith(
      error: null,
      validationErrors: null,
    ));
  }

  // Add cleanup for failed auth states
  Future<void> handleFailedAuth() async {
    try {
      await _notificationService.unsubscribe();
    } catch (e) {
      developer.log(
        'Error during failed auth cleanup: $e',
        name: 'AuthCubit',
      );
    }
  }
}
