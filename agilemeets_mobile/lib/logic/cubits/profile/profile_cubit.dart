import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../data/models/profile/complete_profile_dto.dart';
import '../../../data/models/profile/update_profile_dto.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/exceptions/validation_exception.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileState.initial());

  Future<void> loadProfile(String userId) async {
    try {
      emit(state.copyWith(status: ProfileStatus.loading));
      
      final profile = await _profileRepository.getProfileInformation(userId);
      
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
      ));
    } catch (e) {
      developer.log(
        'Error loading profile: $e',
        name: 'ProfileCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> completeProfile(CompleteProfileDTO dto) async {
    try {
      emit(state.copyWith(status: ProfileStatus.updating));
      
      final success = await _profileRepository.completeProfile(dto);
      
      if (success) {
        emit(state.copyWith(status: ProfileStatus.completed));
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          error: 'Failed to complete profile',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error completing profile: $e',
        name: 'ProfileCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> updateProfile(UpdateProfileDTO dto, String userId) async {
    try {
      emit(state.copyWith(status: ProfileStatus.updating));
      
      final responseUserId = await _profileRepository.updateProfile(dto, userId);
      
      if (responseUserId.isNotEmpty) {
        // Reload profile to get updated information

        emit(state.copyWith(status: ProfileStatus.completed));
        await loadProfile(userId);
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          error: 'Failed to update profile',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error updating profile: $e',
        name: 'ProfileCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      emit(state.copyWith(status: ProfileStatus.updating));
      
      final success = await _profileRepository.changePassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      
      if (success) {
        emit(state.copyWith(
          status: ProfileStatus.completed,
          isPasswordChangeRequired: false,
        ));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          error: 'Failed to change password',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error changing password: $e',
        name: 'ProfileCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
      ));
    }
  }
} 