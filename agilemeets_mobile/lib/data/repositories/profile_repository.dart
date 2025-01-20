import 'dart:developer' as developer;
import '../models/api_response.dart';
import '../models/profile/complete_profile_dto.dart';
import '../models/profile/profile_dto.dart';
import '../models/profile/update_profile_dto.dart';
import 'base_repository.dart';

class ProfileRepository extends BaseRepository {
  Future<bool> completeProfile(CompleteProfileDTO dto) async {
    try {
      final response = await apiClient.put(
        '/api/Auth/CompleteProfile',
        data: dto.toJson(),
      );

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (data) => data as bool,
      );

      if (apiResponse.statusCode == 200) {
        return apiResponse.data ?? false;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to complete profile');
      }
    } catch (e) {
      developer.log(
        'Error completing profile: $e',
        name: 'ProfileRepository',
        error: e,
      );
      rethrow;
    }
  }

  Future<ProfileDTO> getProfileInformation(String userId) async {
    try {
      final response = await apiClient.get(
        '/api/UserAccount/GetProfileInformation',
        queryParameters: {'userId': userId},
      );

      final apiResponse = ApiResponse<ProfileDTO>.fromJson(
        response.data,
        (data) => ProfileDTO.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.statusCode == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to get profile information');
      }
    } catch (e) {
      developer.log(
        'Error getting profile information: $e',
        name: 'ProfileRepository',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> updateProfile(UpdateProfileDTO dto, String userId) async {
    try {
      final response = await apiClient.put(
        '/api/UserAccount/UpdateProfile',
        data: dto.toJson(),
      );

      final apiResponse = ApiResponse<String>.fromJson(
        response.data,
        (data) => data as String,
      );

      if (apiResponse.statusCode == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to update profile');
      }
    } catch (e) {
      developer.log(
        'Error updating profile: $e',
        name: 'ProfileRepository',
        error: e,
      );
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/UserAccount/ChangePassword',
        data: {
          'userId': userId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (data) => data as bool,
      );

      if (apiResponse.statusCode == 200) {
        return apiResponse.data ?? false;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to change password');
      }
    } catch (e) {
      developer.log(
        'Error changing password: $e',
        name: 'ProfileRepository',
        error: e,
      );
      rethrow;
    }
  }
} 