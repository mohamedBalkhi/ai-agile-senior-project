import 'dart:io';
import 'dart:developer';
import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/enums/meeting_status.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/models/modify_recurring_meeting_dto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agilemeets/data/repositories/meeting_repository.dart';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'dart:developer' as developer;
import 'meeting_state.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as dev;
import 'package:agilemeets/data/models/grouped_meetings_response.dart';
import 'package:agilemeets/data/models/meeting_ai_report_dto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MeetingCubit extends Cubit<MeetingState> {
  final MeetingRepository _repository;
  static const int pageSize = 10;

  MeetingCubit(this._repository) : super(const MeetingState());

  CancelToken? _uploadCancelToken;

  @override
  Future<void> close() {
    _uploadCancelToken?.cancel();
    return super.close();
  }

  Future<void> loadProjectMeetings(
    String projectId, {
    bool refresh = false,
    bool loadMore = false,
    bool loadPast = true,
    bool upcomingOnly = true,
  }) async {
    try {
      // Don't load more if we're already loading
      if ((state.status == MeetingStateStatus.loading && !refresh) || 
          state.isLoadingMore) {
        return;
      }

      // Don't load more if we have no more meetings in the requested direction
      if (loadMore && !refresh) {
        if (loadPast && !state.hasMorePast) return;
        if (!loadPast && !state.hasMoreFuture) return;
      }

      // For loading more, we use the oldest/newest dates as boundaries
      DateTime? fromDate;
      DateTime? toDate;
      
      if (loadMore && !refresh) {
        if (loadPast) {
          // For past meetings, use oldestMeetingDate as toDate
          toDate = state.oldestMeetingDate;
        } else {
          // For future meetings, use newestMeetingDate as fromDate
          fromDate = state.newestMeetingDate;
        }
      }

      if (refresh) {
        emit(state.copyWith(
          status: MeetingStateStatus.loading,
          error: null,
          isRefreshing: true,
          // On refresh, keep existing meetings but reset pagination markers
          hasMorePast: true,
          hasMoreFuture: true,
          oldestMeetingDate: null,
          newestMeetingDate: null,
        ));
      } else if (loadMore) {
        emit(state.copyWith(
          isLoadingMore: true,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.loading,
          error: null,
        ));
      }

      final response = await _repository.getProjectMeetings(
        projectId,
        upcomingOnly: upcomingOnly,
        fromDate: fromDate,
        toDate: toDate,
        pageSize: 10,
      );

      if (response.data != null) {
        final newGroups = response.data!.groups;
        
        // Handle groups update
        final updatedGroups = refresh 
            ? newGroups 
            : _mergeGroups(
                state.groups ?? [], 
                newGroups, 
                loadPast,
                // Pass current boundaries to ensure proper merging
                currentOldest: state.oldestMeetingDate,
                currentNewest: state.newestMeetingDate,
              );

        // Update date boundaries
        DateTime? newOldestDate = response.data!.oldestMeetingDate;
        DateTime? newNewestDate = response.data!.newestMeetingDate;
        
        if (!refresh && loadMore) {
          // When loading more, preserve the opposite boundary
          if (loadPast) {
            newNewestDate = state.newestMeetingDate;
          } else {
            newOldestDate = state.oldestMeetingDate;
          }
        }

        emit(state.copyWith(
          status: MeetingStateStatus.loaded,
          groups: updatedGroups,
          hasMorePast: response.data!.hasMorePast,
          hasMoreFuture: response.data!.hasMoreFuture,
          oldestMeetingDate: newOldestDate,
          newestMeetingDate: newNewestDate,
          isRefreshing: false,
          isLoadingMore: false,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to load meetings',
          isRefreshing: false,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      developer.log(
        'Error loading meetings: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
        isRefreshing: false,
        isLoadingMore: false,
      ));
    }
  }

  // Update the merge groups function to handle ordering correctly
  List<MeetingGroupDTO> _mergeGroups(
    List<MeetingGroupDTO> existing,
    List<MeetingGroupDTO> newGroups,
    bool loadingPast, {
    DateTime? currentOldest,
    DateTime? currentNewest,
  }) {
    final groupMap = <String, MeetingGroupDTO>{};
    
    // First, add all existing groups to the map
    for (final group in existing) {
      groupMap[group.date.toIso8601String()] = group;
    }
    
    // Then add or update with new groups
    for (final group in newGroups) {
      final dateKey = group.date.toIso8601String();
      
      // When loading past, only add groups older than currentOldest
      // When loading future, only add groups newer than currentNewest
      if (loadingPast && currentOldest != null) {
        if (group.date.isAfter(currentOldest)) continue;
      } else if (!loadingPast && currentNewest != null) {
        if (group.date.isBefore(currentNewest)) continue;
      }
      
      if (groupMap.containsKey(dateKey)) {
        // If the group already exists, merge the meetings and remove duplicates
        final existingMeetings = groupMap[dateKey]!.meetings;
        final newMeetings = group.meetings;
        
        // Create a map to remove duplicates based on meeting ID
        final meetingMap = <String, MeetingDTO>{};
        for (final meeting in existingMeetings) {
          meetingMap[meeting.id] = meeting;
        }
        for (final meeting in newMeetings) {
          meetingMap[meeting.id] = meeting;
        }
        
        // Create a new group with merged meetings
        groupMap[dateKey] = MeetingGroupDTO(
          groupTitle: group.groupTitle,
          date: group.date,
          meetings: meetingMap.values.toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
      } else {
        groupMap[dateKey] = group;
      }
    }
    
    // Convert back to sorted list
    final merged = groupMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return merged;
  }

  Future<void> loadMeetingDetails(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.loading,
        error: null, // Clear previous error
      ));

      final response = await _repository.getMeetingDetails(meetingId);

      if (response.data != null) {
        emit(state.copyWith(
          status: MeetingStateStatus.loaded,
          selectedMeeting: response.data,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to load meeting details',
        ));
      }
    } catch (e) {
      developer.log(
        'Error loading meeting details: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> createMeeting({
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
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.creating,
        error: null,
        validationErrors: null,
      ));

      final response = await _repository.createMeeting(
        title: title,
        goal: goal,
        language: language,
        type: type,
        startTime: startTime,
        endTime: endTime,
        timeZone: timeZone,
        projectId: projectId,
        memberIds: memberIds,
        location: location,
        reminderTime: reminderTime,
        audioFile: audioFile,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
      );

      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(status: MeetingStateStatus.created));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to create meeting',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error creating meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> updateMeeting({
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
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
        validationErrors: null,
      ));

      final response = await _repository.updateMeeting(
        meetingId: meetingId,
        title: title,
        goal: goal,
        language: language,
        startTime: startTime,
        endTime: endTime,
        timeZone: timeZone,
        location: location,
        reminderTime: reminderTime,
        addMembers: addMembers,
        removeMembers: removeMembers,
        recurringPattern: recurringPattern,
      );

      if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to update meeting',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error updating meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> cancelMeeting(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
      ));

      final response = await _repository.cancelMeeting(meetingId);

       if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
        
        // Refresh meeting list if we have a current project
        if (state.groups != null && state.selectedMeeting != null) {
          await loadProjectMeetings(
            state.selectedMeeting!.projectId ?? '',
            refresh: true,
          );
        } else if (state.groups != null && state.groups!.isNotEmpty) {
          final firstMeeting = state.groups!.first.meetings.firstOrNull;
          if (firstMeeting != null) {
            await loadProjectMeetings(
              firstMeeting.projectId ?? '',
              refresh: true,
            );
          }
        }
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to cancel meeting',
        ));
      }
    } catch (e) {
      developer.log(
        'Error cancelling meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> startMeeting(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
      ));

      final response = await _repository.startMeeting(meetingId);

      if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to start meeting',
        ));
      }
    } catch (e) {
      developer.log(
        'Error starting meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> completeMeeting(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
      ));

      final response = await _repository.completeMeeting(meetingId);

      if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to complete meeting',
        ));
      }
    } catch (e) {
      developer.log(
        'Error completing meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> joinMeeting(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.joiningMeeting,
        error: null,
      ));

      final response = await _repository.joinMeeting(meetingId);

      if (response.data != null) {
        emit(state.copyWith(
          status: MeetingStateStatus.joinedMeeting,
          joinMeetingResponse: response.data,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to join meeting',
        ));
      }
    } catch (e) {
      developer.log(
        'Error joining meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> confirmAttendance(String meetingId, bool confirmed) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
      ));

      final response = await _repository.confirmAttendance(meetingId, confirmed);

      if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to confirm attendance',
        ));
      }
    } catch (e) {
      developer.log(
        'Error confirming attendance: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadAudio(String meetingId, File audioFile) async {
    try {
      _uploadCancelToken?.cancel();
      _uploadCancelToken = CancelToken();

      emit(state.copyWith(
        isAudioUploading: true,
        audioUploadProgress: 0,
        error: null,
      ));

      final response = await _repository.uploadAudio(
        meetingId,
        audioFile,
        onProgress: (progress) {
          emit(state.copyWith(audioUploadProgress: progress));
        },
        cancelToken: _uploadCancelToken,
      );

      if (response.data != null) {
        emit(state.copyWith(
          isAudioUploading: false,
          audioUploadProgress: 1.0,
          audioUrl: response.data,
        ));
        await loadMeetingDetails(meetingId);
      } else {
        emit(state.copyWith(
          isAudioUploading: false,
          audioUploadProgress: null,
          error: response.message ?? 'Failed to upload audio',
        ));
      }
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        developer.log(
          'Error uploading audio: $e',
          name: 'MeetingCubit',
          error: e,
        );
        emit(state.copyWith(
          isAudioUploading: false,
          audioUploadProgress: null,
          error: e.toString(),
        ));
      }
    }
  }

  void cancelAudioUpload() {
    _uploadCancelToken?.cancel();
    _uploadCancelToken = null;
    emit(state.copyWith(
      isAudioUploading: false,
      audioUploadProgress: null,
    ));
  }

  Future<void> modifyRecurringMeeting(
    String meetingId, {
    required bool applyToSeries,
    MeetingStatus? status,
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
  }) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.updating,
        error: null,
      ));

      final dto = ModifyRecurringMeetingDTO(
        applyToSeries: applyToSeries,
        status: status,
        title: title,
        goal: goal,
        language: language,
        startTime: startTime,
        endTime: endTime,
        timeZone: timeZone,
        location: location,
        reminderTime: reminderTime,
        addMembers: addMembers,
        removeMembers: removeMembers,
      );

      final response = await _repository.modifyRecurringMeeting(meetingId, dto);

      if (response.data == true) {
        emit(state.copyWith(status: MeetingStateStatus.updated));
        await loadMeetingDetails(meetingId);
        
        // Refresh meeting list if we have a current project
        if (state.groups != null && state.selectedMeeting != null) {
          await loadProjectMeetings(
            state.selectedMeeting!.projectId ?? '',
            refresh: true,
          );
        } else if (state.groups != null && state.groups!.isNotEmpty) {
          final firstMeeting = state.groups!.first.meetings.firstOrNull;
          if (firstMeeting != null) {
            await loadProjectMeetings(
              firstMeeting.projectId ?? '',
              refresh: true,
            );
          }
        }
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to modify recurring meeting',
        ));
      }
    } catch (e) {
      developer.log(
        'Error modifying recurring meeting: $e',
        name: 'MeetingCubit',
        error: e,
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<String?> downloadMeetingAudio(String meetingId, {String? cachedFile}) async {
    try {
      if (cachedFile != null && File(cachedFile).existsSync()) {
        // If we have a cached file, copy it to downloads instead of downloading again
        final downloadDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(cachedFile);
        final targetPath = path.join(downloadDir.path, 'meeting_audio', fileName);
        
        // Create directory if it doesn't exist
        final dir = Directory(path.dirname(targetPath));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        // Copy the cached file
        await File(cachedFile).copy(targetPath);
        return targetPath;
      }
      
      // If no cached file, download normally
      return await _repository.downloadMeetingAudio(meetingId);
    } catch (e) {
      dev.log('Error downloading audio: $e', name: 'MeetingCubit');
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<String> getMeetingAudioUrl(String meetingId) async {
    try {
      final audioUrl = await _repository.getMeetingAudioUrl(meetingId);
      dev.log('Got audio URL: $audioUrl', name: 'MeetingCubit');
      return audioUrl;
    } catch (e) {
      dev.log('Error getting audio URL: $e', name: 'MeetingCubit');
      rethrow;
    }
  }

  Future<void> uploadMeetingAudio(String meetingId, String audioPath) async {
    try {
      emit(state.copyWith(status: MeetingStateStatus.loading));
      await _repository.uploadMeetingAudio(meetingId, audioPath);
      await loadMeetingDetails(meetingId); // Reload meeting details
    } catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMeetingAIReport(String meetingId) async {
    try {
      emit(state.copyWith(status: MeetingStateStatus.loadingAIReport));

      final response = await _repository.getMeetingAIReport(meetingId);
      
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(
          status: MeetingStateStatus.aiReportLoaded,
          aiReport: response.data,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to load AI report',
        ));
      }
    } on AppException catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: 'An unexpected error occurred while loading the AI report',
      ));
    }
  }
}