import 'dart:developer';
import 'dart:io';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/data/models/api_response.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/models/meeting_details_dto.dart';
import 'package:agilemeets/data/models/modify_recurring_meeting_dto.dart';
import 'package:agilemeets/data/models/meeting_ai_report_dto.dart';
import 'package:agilemeets/data/repositories/base_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/models/audio_url_response.dart';
import 'package:agilemeets/data/models/grouped_meetings_response.dart';
import 'package:agilemeets/data/models/join_meeting_response.dart';

class MeetingRepository extends BaseRepository {
  Future<ApiResponse<GroupedMeetingsResponse>> getProjectMeetings(
    String projectId, {
    bool upcomingOnly = true,
    DateTime? fromDate,
    DateTime? toDate,
    int pageSize = 10,
  }) async {
    return safeApiCall(
      context: 'getProjectMeetings',
      call: () async {
        final response = await apiClient.get(
          '/api/Meeting/GetProjectMeetings',
          queryParameters: {
            'projectId': projectId,
            'upcomingOnly': upcomingOnly,
            if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
            if (toDate != null) 'toDate': toDate.toIso8601String(),
            'pageSize': pageSize,
          },
        );

        return ApiResponse<GroupedMeetingsResponse>.fromJson(
          response.data,
          (json) => GroupedMeetingsResponse.fromJson(json as Map<String, dynamic>),
        );
      },
    );
  }

  Future<ApiResponse<MeetingDetailsDTO>> getMeetingDetails(String meetingId) async {
    return safeApiCall(
      context: 'getMeetingDetails',
      call: () async {
        final response = await apiClient.get(
          '/api/Meeting/GetMeetingDetails',
          queryParameters: {'meetingId': meetingId},
        );

        return ApiResponse<MeetingDetailsDTO>.fromJson(
          response.data,
          (json) => MeetingDetailsDTO.fromJson(json as Map<String, dynamic>),
        );
      },
    );
  }

  Future<ApiResponse<String>> createMeeting({
    required String title,
    String? goal,
    required int language,
    required int type,
    required DateTime startTime,
    required DateTime endTime,
    required String timeZone,
    required String projectId,
    required List<String> memberIds,
    String? location,
    DateTime? reminderTime,
    File? audioFile,
    bool isRecurring = false,
    Map<String, dynamic>? recurringPattern,
  }) async {
    return safeApiCall(
      context: 'createMeeting',
      call: () async {
        final formData = FormData.fromMap({
          'Title': title,
          'Goal': goal,
          'Language': language,
          'Type': type,
          'StartTime': startTime.toIso8601String(),
          'EndTime': endTime.toIso8601String(),
          'TimeZone': timeZone,
          'ProjectId': projectId,
          'MemberIds': memberIds,
          'Location': location,
          'ReminderTime': reminderTime?.toIso8601String(),
          'IsRecurring': isRecurring,
          if (audioFile != null)
            'AudioFile': await MultipartFile.fromFile(audioFile.path),
          if (recurringPattern != null) ...{
            'RecurringPattern.RecurrenceType': recurringPattern['recurrenceType'],
            'RecurringPattern.Interval': recurringPattern['interval'],
            'RecurringPattern.RecurringEndDate': recurringPattern['recurringEndDate'],
            'RecurringPattern.DaysOfWeek': recurringPattern['daysOfWeek'],
          },
        });

        final response = await apiClient.post(
          '/api/Meeting/CreateMeeting',
          data: formData,
        );

        return ApiResponse<String>.fromJson(
          response.data,
          (json) => json as String,
        );
      },
    );
  }

  Future<ApiResponse<bool>> updateMeeting({
    required String meetingId,
    String? title,
    String? goal,
    MeetingLanguage? language,
    DateTime? startTime,
    DateTime? endTime,
    String? timeZone,
    String? location,
    DateTime? reminderTime,
    List<String>? addMembers,
    List<String>? removeMembers,
    Map<String, dynamic>? recurringPattern,
  }) async {
    return safeApiCall(
      context: 'updateMeeting',
      call: () async {
        final formData = FormData.fromMap({
          'MeetingId': meetingId,
          if (title != null) 'Title': title,
          if (goal != null) 'Goal': goal,
          if (language != null) 'Language': language.value,
          if (startTime != null) 'StartTime': startTime.toIso8601String(),
          if (endTime != null) 'EndTime': endTime.toIso8601String(),
          if (timeZone != null) 'TimeZone': timeZone,
          if (location != null) 'Location': location,
          if (reminderTime != null) 'ReminderTime': reminderTime.toIso8601String(),
          if (addMembers != null) 'AddMembers': addMembers,
          if (removeMembers != null) 'RemoveMembers': removeMembers,
          if (recurringPattern != null) ...{
            'RecurringPattern.RecurrenceType': recurringPattern['recurrenceType'],
            'RecurringPattern.Interval': recurringPattern['interval'],
            'RecurringPattern.RecurringEndDate': recurringPattern['recurringEndDate'],
            'RecurringPattern.DaysOfWeek': recurringPattern['daysOfWeek'],
          },
        });

        final response = await apiClient.put(
          '/api/Meeting/UpdateMeeting',
          data: formData,
        );

        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<ApiResponse<bool>> cancelMeeting(String meetingId) async {
    return safeApiCall(
      context: 'cancelMeeting',
      call: () async {
        final response = await apiClient.delete(
          '/api/Meeting/CancelMeeting',
          queryParameters: {'meetingId': meetingId},
        );

        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<ApiResponse<String>> uploadAudio(
    String meetingId,
    File audioFile, {
    void Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return safeApiCall(
      context: 'uploadAudio',
      call: () async {
        final formData = FormData.fromMap({
          'audioFile': await MultipartFile.fromFile(
            audioFile.path,
            filename: audioFile.path.split('/').last,
          ),
        });

        final response = await apiClient.post(
          '/api/Meeting/$meetingId/UploadAudio',
          data: formData,
          cancelToken: cancelToken,
          onSendProgress: (sent, total) {
            if (total != -1 && onProgress != null) {
              onProgress(sent / total);
            }
          },
        );

        return ApiResponse<String>.fromJson(
          response.data,
          (json) => json as String,
        );
      },
    );
  }

  Future<String> getMeetingAudioUrl(String meetingId) async {
    return safeApiCall(
      context: 'getMeetingAudioUrl',
      call: () async {
        final response = await apiClient.get(
          '/api/Meeting/$meetingId/AudioUrl',
        );
        
        final apiResponse = ApiResponse.fromJson(
          response.data,
          (json) => AudioUrlResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.data != null) {
          return apiResponse.data!.preSignedUrl;
        }
        
        throw const ServerException(
          'Failed to get audio URL',
          code: 'INVALID_RESPONSE',
        );
      },
    );
  }

  Future<String?> downloadMeetingAudio(String meetingId) async {
    try {
      // Request appropriate permissions based on Android version
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        log('Android SDK version: $sdkInt', name: 'MeetingRepository');

        if (sdkInt >= 33) {
          // For Android 13 and above
          final status = await Permission.audio.status;
          if (status.isDenied || status.isRestricted) {
            final result = await Permission.audio.request();
            if (!result.isGranted) {
              throw Exception('Audio permission is required to download files. Please enable it in app settings.');
            }
          } else if (status.isPermanentlyDenied) {
            throw Exception('Audio permission is permanently denied. Please enable it in app settings.');
          }
        } else {
          // For below Android 13
          final status = await Permission.storage.status;
          if (status.isDenied || status.isRestricted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
              throw Exception('Storage permission is required to download files. Please enable it in app settings.');
            }
          } else if (status.isPermanentlyDenied) {
            throw Exception('Storage permission is permanently denied. Please enable it in app settings.');
          }
        }
      }

      // Download file with content type detection
      final response = await apiClient.get(
        '/api/Meeting/$meetingId/Audio',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'audio/*',
          },
        ),
      );

      final bytes = response.data;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Get content type from response headers
      final contentType = response.headers.value('content-type');
      String extension = '.mp3'; // Default extension
      
      // Map common audio MIME types to extensions
      if (contentType != null) {
        switch(contentType.toLowerCase()) {
          case 'audio/wav':
          case 'audio/x-wav':
            extension = '.wav';
            break;
          case 'audio/mpeg':
            extension = '.mp3';
            break;
          case 'audio/mp4':
          case 'audio/x-m4a':
            extension = '.m4a';
            break;
          case 'audio/aac':
            extension = '.aac';
            break;
        }
      }

      final fileName = 'meeting_${meetingId}_$timestamp$extension';

      // Save file using flutter_file_dialog
      final params = SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath == null) {
        throw Exception('File save canceled or failed');
      }

      return filePath;
    } catch (e) {
      // Handle exceptions
      rethrow;
    }
  }

  Future<ApiResponse<MeetingAIReportDTO>> getMeetingAIReport(String meetingId) async {
    return safeApiCall(
      context: 'getMeetingAIReport',
      call: () async {
        final response = await apiClient.get(
          '/api/Meeting/$meetingId/AIReport',
        );

        return ApiResponse<MeetingAIReportDTO>.fromJson(
          response.data,
          (json) => MeetingAIReportDTO.fromJson(json as Map<String, dynamic>),
        );
      },
    );
  }

  Future<ApiResponse<bool>> startMeeting(String meetingId) async {
    return safeApiCall(
      context: 'startMeeting',
      call: () async {
        final response = await apiClient.post('/api/Meeting/$meetingId/Start');
        
        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<ApiResponse<bool>> completeMeeting(String meetingId) async {
    return safeApiCall(
      context: 'completeMeeting',
      call: () async {
        final response = await apiClient.post('/api/Meeting/$meetingId/Complete');
        
        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<ApiResponse<bool>> confirmAttendance(String meetingId, bool confirmed) async {
    return safeApiCall(
      context: 'confirmAttendance',
      call: () async {
        final response = await apiClient.post(
          '/api/Meeting/$meetingId/Confirm',
          data: confirmed,
        );
        
        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<ApiResponse<JoinMeetingResponse>> joinMeeting(String meetingId) async {
    return safeApiCall(
      context: 'joinMeeting',
      call: () async {
        final response = await apiClient.post(
          '/api/Meeting/$meetingId/Join',
        );
        
        return ApiResponse<JoinMeetingResponse>.fromJson(
          response.data,
          (json) => JoinMeetingResponse.fromJson(json as Map<String, dynamic>),
        );
      },
    );
  }

  Future<ApiResponse<bool>> modifyRecurringMeeting(
    String meetingId,
    ModifyRecurringMeetingDTO dto,
  ) async {
    return safeApiCall(
      context: 'modifyRecurringMeeting',
      call: () async {
        final response = await apiClient.post(
          '/api/Meeting/$meetingId/ModifyRecurring',
          data: dto.toJson(),
        );
        
        return ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );
      },
    );
  }

  Future<void> uploadMeetingAudio(String meetingId, String audioPath) async {
    try {
      final formData = FormData.fromMap({
        'audioFile': await MultipartFile.fromFile(audioPath),
      });
      
      await apiClient.post(
        '/api/Meeting/$meetingId/UploadAudio',
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }
}