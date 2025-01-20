import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/profile/profile_dto.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  completed,
  error,
  validationError,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileDTO? profile;
  final String? error;
  final List<ValidationError>? validationErrors;
  final bool isPasswordChangeRequired;

  const ProfileState({
    required this.status,
    this.profile,
    this.error,
    this.validationErrors,
    this.isPasswordChangeRequired = false,
  });

  factory ProfileState.initial() => const ProfileState(
        status: ProfileStatus.initial,
      );

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileDTO? profile,
    String? error,
    List<ValidationError>? validationErrors,
    bool? isPasswordChangeRequired,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error ?? this.error,
      validationErrors: validationErrors ?? this.validationErrors,
      isPasswordChangeRequired: isPasswordChangeRequired ?? this.isPasswordChangeRequired,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        error,
        validationErrors,
        isPasswordChangeRequired,
      ];
} 