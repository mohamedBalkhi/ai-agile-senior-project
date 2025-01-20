import 'package:equatable/equatable.dart';
import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:agilemeets/models/decoded_token.dart';
import 'package:agilemeets/data/models/auth_result.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailVerificationRequired,
  organizationCreationRequired,
  profileCompletionRequired,
  error,
  validationError,
  resetCodeSent,
  resetCodeVerified,
  passwordResetSuccess,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final DecodedToken? decodedToken;
  final String? error;
  final List<ValidationError>? validationErrors;
  final String? userId;
  final String? email;
  final String? password;
  final bool isAdmin;
  final bool isTrusted;
  final bool isActive;
  final bool isInSignupFlow;
  final AuthResult? authResult;

  const AuthState({
    this.status = AuthStatus.initial,
    this.decodedToken,
    this.error,
    this.validationErrors,
    this.userId,
    this.email,
    this.password,
    this.isAdmin = false,
    this.isTrusted = false,
    this.isActive = false,
    this.isInSignupFlow = false,
    this.authResult,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    AuthStatus? status,
    DecodedToken? decodedToken,
    String? error,
    List<ValidationError>? validationErrors,
    String? userId,
    String? email,
    String? password,
    bool? isAdmin,
    bool? isTrusted,
    bool? isActive,
    bool? isInSignupFlow,
    AuthResult? authResult,
  }) {
    return AuthState(
      status: status ?? this.status,
      decodedToken: decodedToken ?? this.decodedToken,
      error: error,
      validationErrors: validationErrors,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
      isTrusted: isTrusted ?? this.isTrusted,
      isActive: isActive ?? this.isActive,
      isInSignupFlow: isInSignupFlow ?? this.isInSignupFlow,
      authResult: authResult ?? this.authResult,
    );
  }
  // get userEmail
  String? get userEmail => email ?? decodedToken?.email;
  // get userIdentifier
  String? get userIdentifier => userId ?? decodedToken?.userId;
  @override
  List<Object?> get props => [
    status,
    decodedToken,
    error,
    validationErrors,
    userId,
    email,
    password,
    isAdmin,
    isTrusted,
    isActive,
    isInSignupFlow,
    authResult,
  ];

  Map<String, List<String>> get validationErrorsMap {
    if (validationErrors == null) return {};
    
    final map = <String, List<String>>{};
    for (final error in validationErrors!) {
      final key = error.propertyName.split('.').last.toLowerCase();
      map.putIfAbsent(key, () => []).add(error.errorMessage);
    }
    return map;
  }
}
