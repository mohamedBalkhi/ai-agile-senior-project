import 'dart:developer' as developer;

import 'package:agilemeets/data/models/api_response.dart';
import 'package:agilemeets/data/models/forgot_password_dto.dart';
import 'package:agilemeets/data/models/auth_result.dart';
import 'package:agilemeets/data/models/sign_up_dto.dart';
import 'package:agilemeets/data/models/sign_up_response.dart';
import 'package:agilemeets/models/decoded_token.dart';
import 'package:agilemeets/utils/secure_storage.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  Future<AuthResult> login(String email, String password) async {
    validateParams({
      'email': email,
      'password': password,
    });

    return safeApiCall(
      context: 'login',
      call: () async {
        final response = await apiClient.post(
          '/api/Auth/login',
          data: {
            'email': email,
            'password': password,
          },
        );

        return handleResponse(
          response: response.data,
          context: 'login response',
          onSuccess: (data) async {
            final authResult = AuthResult.fromJson(data['data']);
            await _saveTokens(authResult);
            return authResult;
          },
        );
      },
    );
  }

  Future<SignUpResponse> signUp(SignUpDTO signUpDTO) async {
    return safeApiCall(
      context: 'signup',
      call: () async {
        final response = await apiClient.post(
          '/api/Auth/signup',
          data: signUpDTO.toJson(),
        );

        return handleResponse(
          response: response.data,
          context: 'signup response',
          onSuccess: (data) {
            return SignUpResponse(
              userId: data['data'],
              email: signUpDTO.email,
            );
          },
        );
      },
    );
  }

  Future<bool> verifyEmail(String code, String userId) async {
    validateParams({
      'code': code,
      'userId': userId,
    });

    return safeApiCall(
      context: 'verify email',
      call: () async {
        final response = await apiClient.post(
          '/api/Auth/VerifyEmail',
          data: {
            'code': code,
            'userId': userId,
          },
        );

        return handleResponse(
          response: response.data,
          context: 'verify email response',
          onSuccess: (data) => data['data'] as bool,
        );
      },
    );
  }

  Future<String> resendCode(String userId) async {
    validateParams({
      'UserID': userId,
    });

    return safeApiCall(
      context: 'resend code',
      call: () async {
        final response = await apiClient.post(
          '/api/Auth/ResendCode',
          queryParameters: {
            'UserID': userId,
          },
        );

        return handleResponse(
          response: response.data,
          context: 'resend code response',
          onSuccess: (data) => data['data'] as String,
        );
      },
    );
  }

  Future<void> logout() async {
    try {
      developer.log('Initiating logout', name: 'AuthRepository');
      // Call logout endpoint to invalidate refresh token (cookie)
      await apiClient.post('/api/Auth/logout');
      // Clear all stored tokens
      await SecureStorage.deleteAllTokens();
      developer.log('Logout completed', name: 'AuthRepository');
    } catch (e) {
      developer.log('Error during logout: $e', name: 'AuthRepository', error: e);
      // Still clear tokens even if API call fails
      await SecureStorage.deleteAllTokens();
      rethrow;
    }
  }

  Future<void> _saveTokens(AuthResult authResult) async {
    if (authResult.accessToken != null) {
      await SecureStorage.saveToken('access_token', authResult.accessToken!);
      final decodedToken = DecodedToken.fromJwt(authResult.accessToken!);
      await SecureStorage.saveDecodedToken(decodedToken);
    }
    // Remove refresh token handling as it's managed by HttpOnly cookie
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await SecureStorage.getToken('access_token');
      if (token == null) return false;

      // Check if token is expired
      final isExpired = await SecureStorage.isTokenExpired();
      if (isExpired) {
        // Try to refresh the token instead of immediately logging out
        developer.log('Token expired, attempting refresh...', name: 'AuthRepository');
        final newToken = await apiClient.refreshToken();
        
        if (newToken != null) {
          developer.log('Token refresh successful', name: 'AuthRepository');
          return true;
        }
        
        developer.log('Token refresh failed', name: 'AuthRepository');
        await SecureStorage.deleteAllTokens();
        return false;
      }

      // Validate token format
      try {
        final decodedToken = DecodedToken.fromJwt(token);
        if (decodedToken.isExpired) {
          // Try to refresh here as well
          final newToken = await apiClient.refreshToken();
          return newToken != null;
        }
        return true;
      } catch (e) {
        developer.log('Token validation failed: $e', name: 'AuthRepository');
        await SecureStorage.deleteAllTokens();
        return false;
      }
    } catch (e) {
      developer.log('Error checking login status: $e', name: 'AuthRepository');
      return false;
    }
  }

  Future<DecodedToken?> getDecodedToken() async {
    return await SecureStorage.getDecodedToken();
  }

  Future<bool> forgotPassword(ForgotPasswordDTO dto) async {
    try {
      final response = await apiClient.post(
        '/api/UserAccount/ForgetPassword',
        data: dto.toJson(),
      );
      
      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (data) => data as bool,
      );

      if (apiResponse.statusCode == 200) {
        return apiResponse.data ?? false;
      } else {
        throw Exception(apiResponse.message ?? 'Password reset failed');
      }
    } catch (e) {
      developer.log('Forgot password error: $e', name: 'AuthRepository');
      rethrow;
    }
  }

  Future<String> requestPasswordReset(String email) async {
    try {
      final response = await apiClient.post(
        '/api/UserAccount/RequestPasswordReset', 
        data: {
          'email': email,
        }
      );
      
      final apiResponse = ApiResponse<String>.fromJson(
        response.data,
        (data) => data as String,  // Changed back to String to get userId
      );

      if (apiResponse.statusCode == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to request password reset');
      }
    } catch (e) {
      developer.log('Password reset request error: $e', name: 'AuthRepository');
      rethrow;
    }
  }
}
