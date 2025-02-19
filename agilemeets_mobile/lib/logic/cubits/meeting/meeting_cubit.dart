import 'dart:io';
import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/enums/meeting_status.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/models/modify_recurring_meeting_dto.dart';
import 'package:agilemeets/data/models/recording_metadata.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agilemeets/data/repositories/meeting_repository.dart';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'dart:developer' as developer;
import 'meeting_state.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as dev;
import 'package:agilemeets/data/models/grouped_meetings_response.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../services/recording_manager.dart';
import '../../../services/recording_storage_service.dart';
import '../../../services/upload_manager.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

enum RecordingAction {
  start,
  stop,
  pause,
  resume,
  upload,
  saveForLater,
  discard,
}

class MeetingCubit extends Cubit<MeetingState> {
  final MeetingRepository _repository;
  final RecordingManager _recordingManager;
  final RecordingStorageService _storage;
  final UploadManager _uploadManager;
  static const int pageSize = 10;

  // Add field to track last warning threshold
  Duration? _lastWarningThreshold;

  MeetingCubit(
    this._repository,
    this._recordingManager,
    this._storage,
  ) : _uploadManager = GetIt.I<UploadManager>(),
      super(const MeetingState());

  CancelToken? _uploadCancelToken;
  StreamSubscription? _timerSubscription;
  StreamSubscription? _uploadProgressSubscription;
  StreamSubscription? _uploadStatusSubscription;

  @override
  Future<void> close() {
    dev.log('Closing MeetingCubit', name: 'MeetingCubit');
    _timerSubscription?.cancel();
    _uploadProgressSubscription?.cancel();
    _uploadStatusSubscription?.cancel();
    _recordingManager.dispose();
    _uploadManager.dispose();
    return super.close();
  }

  Future<void> loadProjectMeetings(
  String projectId, {
  bool refresh = false,
  bool loadMore = false,
  bool upcomingOnly = true,
  String? timeZoneId,
}) async {
  try {
    // Validate parameters
    if (projectId.isEmpty) {
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: 'Project ID is required',
      ));
      return;
    }

    if (timeZoneId?.isEmpty ?? true) {
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: 'Timezone is required',
      ));
      return;
    }

    // Check loading states
    if ((state.status == MeetingStateStatus.loading && !refresh) || 
        state.isLoadingMore) {
      return;
    }
    if (loadMore && !refresh && !state.hasMore) {
      return;
    }

    // Update state for loading
    if (refresh) {
      // When refreshing or switching views, clear all pagination state
      emit(state.copyWith(
        status: MeetingStateStatus.loading,
        error: null,
        isRefreshing: true,
        hasMore: true,
        groups: [], // Clear groups when switching views
        // Clear ALL pagination state when refreshing
        lastMeetingId: null,
        pastLastMeetingId: null,
        upcomingLastMeetingId: null,
        pastReferenceDate: null,
        pastNextReferenceDate: null,
        upcomingReferenceDate: null,
        upcomingNextReferenceDate: null,
      ));
    } else if (loadMore) {
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(state.copyWith(status: MeetingStateStatus.loading));
    }

    // Get the appropriate pagination state based on the view
    final currentLastMeetingId = loadMore ? (upcomingOnly 
        ? state.upcomingLastMeetingId 
        : state.pastLastMeetingId) : null;
    final currentReferenceDate = loadMore ? (upcomingOnly
        ? state.upcomingNextReferenceDate
        : state.pastNextReferenceDate) : null;

    // Make API call
    final response = upcomingOnly
        ? await _repository.getUpcomingProjectMeetings(
            projectId,
            timeZoneId: timeZoneId!,
            referenceDate: currentReferenceDate,
            lastMeetingId: currentLastMeetingId,
            pageSize: pageSize,
          )
        : await _repository.getProjectMeetings(
            projectId,
            timeZoneId: timeZoneId!,
            referenceDate: currentReferenceDate,
            lastMeetingId: currentLastMeetingId,
            pageSize: pageSize,
          );

    if (response.data != null) {
      final newGroups = response.data!.groups;
      
      // Handle empty response
      if (refresh && newGroups.isEmpty) {
        emit(state.copyWith(
          status: MeetingStateStatus.loaded,
          groups: [],
          hasMore: false,
          isRefreshing: false,
          isLoadingMore: false,
          timeZoneId: timeZoneId,
          totalMeetingsCount: 0,
          // Clear only the relevant pagination state
          lastMeetingId: null,
          pastLastMeetingId: upcomingOnly ? state.pastLastMeetingId : null,
          upcomingLastMeetingId: upcomingOnly ? null : state.upcomingLastMeetingId,
          pastReferenceDate: upcomingOnly ? state.pastReferenceDate : null,
          pastNextReferenceDate: upcomingOnly ? state.pastNextReferenceDate : null,
          upcomingReferenceDate: upcomingOnly ? null : state.upcomingReferenceDate,
          upcomingNextReferenceDate: upcomingOnly ? null : state.upcomingNextReferenceDate,
        ));
        return;
      }

      // Merge groups if loading more
      final updatedGroups = refresh 
          ? newGroups 
          : _mergeGroups(
              state.groups ?? [],
              newGroups,
              upcomingOnly,
            );

      // Parse reference dates
      final newReferenceDate = DateTime.tryParse(response.data!.referenceDate ?? '');
      final newNextReferenceDate = DateTime.tryParse(response.data!.nextReferenceDate ?? '');

      emit(state.copyWith(
        status: MeetingStateStatus.loaded,
        groups: updatedGroups,
        hasMore: response.data!.hasMore,
        timeZoneId: timeZoneId,
        totalMeetingsCount: response.data!.totalMeetingsCount,
        error: null, // Clear any previous errors
        isRefreshing: false,
        isLoadingMore: false,
        // Update only the relevant pagination state
        lastMeetingId: response.data!.lastMeetingId,
        pastLastMeetingId: upcomingOnly 
            ? state.pastLastMeetingId 
            : response.data!.lastMeetingId,
        upcomingLastMeetingId: upcomingOnly 
            ? response.data!.lastMeetingId 
            : state.upcomingLastMeetingId,
        pastReferenceDate: upcomingOnly 
            ? state.pastReferenceDate 
            : newReferenceDate,
        pastNextReferenceDate: upcomingOnly 
            ? state.pastNextReferenceDate 
            : newNextReferenceDate,
        upcomingReferenceDate: upcomingOnly 
            ? newReferenceDate 
            : state.upcomingReferenceDate,
        upcomingNextReferenceDate: upcomingOnly 
            ? newNextReferenceDate 
            : state.upcomingNextReferenceDate,
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

List<MeetingGroupDTO> _mergeGroups(
  List<MeetingGroupDTO> existing,
  List<MeetingGroupDTO> newGroups,
  bool upcomingOnly,
) {
  final groupMap = <String, MeetingGroupDTO>{};
  
  // First, add all existing groups to the map
  for (final group in existing) {
    groupMap[group.date.toIso8601String()] = group;
  }
  
  // Then add or update with new groups
  for (final group in newGroups) {
    final dateKey = group.date.toIso8601String();
    
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
          ..sort((a, b) => upcomingOnly 
              ? a.startTime.compareTo(b.startTime)
              : b.startTime.compareTo(a.startTime)),
      );
    } else {
      groupMap[dateKey] = group;
    }
  }
  
  // Convert back to sorted list
  final merged = groupMap.values.toList()
    ..sort((a, b) => upcomingOnly 
        ? a.date.compareTo(b.date)
        : b.date.compareTo(a.date));
  
  return merged;
}

  Future<void> loadMeetingDetails(String meetingId) async {
    try {
      emit(state.copyWith(
        status: MeetingStateStatus.loading,
        error: null, // Clear previous error
        // Don't modify groups here
      ));

      final response = await _repository.getMeetingDetails(meetingId);

      if (response.data != null) {
        emit(state.copyWith(
          status: MeetingStateStatus.loaded,
          selectedMeeting: response.data,
          // Keep existing groups
          groups: state.groups,
        ));
      } else {
        emit(state.copyWith(
          status: MeetingStateStatus.error,
          error: response.message ?? 'Failed to load meeting details',
          // Keep existing groups even on error
          groups: state.groups,
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
        // Keep existing groups on error
        groups: state.groups,
      ));
    }
  }

  Future<void> createMeetingWithUpload({
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
  required File audioFile,
  bool isRecurring = false,
  Map<String, dynamic>? recurringPattern,
}) async {
  try {
    // Emit initial state indicating creation has started.
    emit(state.copyWith(
      status: MeetingStateStatus.creating,
      error: null,
      isAudioUploading: true,
      audioUploadProgress: 0,
    ));

    // Create a cancel token to support cancellation.
    _uploadCancelToken = CancelToken();

    // Subscribe to the progress stream BEFORE calling the upload method.
    _uploadProgressSubscription = _uploadManager.progress.listen((progress) {
      emit(state.copyWith(audioUploadProgress: progress));
    });

    // Now call the upload method.
    await _uploadManager.startCreateMeetingUpload(
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

    // On success, update the state.
    emit(state.copyWith(
      status: MeetingStateStatus.created,
      isAudioUploading: false,
      audioUploadProgress: 1.0,
    ));
  } catch (e) {
    emit(state.copyWith(
      status: MeetingStateStatus.error,
      isAudioUploading: false,
      audioUploadProgress: 0,
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
            timeZoneId: state.timeZoneId ?? '',
          );
        } else if (state.groups != null && state.groups!.isNotEmpty) {
          final firstMeeting = state.groups!.first.meetings.firstOrNull;
          if (firstMeeting != null) {
            await loadProjectMeetings(
              firstMeeting.projectId ?? '',
              refresh: true,
              timeZoneId: state.timeZoneId ?? '',
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
      // Create recording metadata
      final recordingId = const Uuid().v4();
      final now = DateTime.now();
      final recording = RecordingMetadata(
        id: recordingId,
        meetingId: meetingId,
        filePath: audioFile.path,
        recordedAt: now,
        fileSize: await audioFile.length(),
        duration: Duration.zero, // Duration is not important for direct uploads
        status: RecordingUploadStatus.pending,
        uploadProgress: 0,
        uploadAttempts: 0,
        lastUploadAttempt: null,
        wasTimeLimited: false,
      );

      // Save recording metadata
      await _storage.saveRecording(recording);

      // Start upload
      await uploadRecording(recording);
    } catch (e) {
      dev.log('Error uploading audio: $e',
        name: 'MeetingCubit',
        error: e
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        isAudioUploading: false,
        audioUploadProgress: 0,
        error: e.toString(),
      ));
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
            timeZoneId: state.timeZoneId ?? '',
          );
        } else if (state.groups != null && state.groups!.isNotEmpty) {
          final firstMeeting = state.groups!.first.meetings.firstOrNull;
          if (firstMeeting != null) {
            await loadProjectMeetings(
              firstMeeting.projectId ?? '',
              refresh: true,
              timeZoneId: state.timeZoneId ?? '',
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

  // New recording methods
  void _handleRecordingTimer() {
    // Cancel any existing subscription
    _timerSubscription?.cancel();
    _timerSubscription = null;
    
    // Reset warning threshold tracking
    _lastWarningThreshold = null;
    
    dev.log('Setting up recording timer subscription', name: 'MeetingCubit');
    
    _timerSubscription = _recordingManager.remainingTime.listen(
      (duration) {
        dev.log('Timer update received - Duration: ${duration.inSeconds}s', 
          name: 'MeetingCubit');

        // Helper function to check and update warning threshold
        bool shouldShowWarning(Duration threshold) {
          // Only show warning if we haven't shown it for this threshold yet
          // and if we're just crossing this threshold
          if (_lastWarningThreshold != threshold && 
              duration.inSeconds <= threshold.inSeconds &&
              duration.inSeconds > (threshold - const Duration(seconds: 1)).inSeconds) {
            dev.log('Showing warning for threshold: ${threshold.inSeconds}s', 
              name: 'MeetingCubit');
            _lastWarningThreshold = threshold;
            return true;
          }
          return false;
        }

        // Check specific thresholds and only show warning once for each
        String? warningMessage;
        if (duration.inSeconds <= 0) {
          // When time limit is reached, stop recording
          if (state.currentRecordingPath != null && state.selectedMeeting != null) {
            dev.log('Time limit reached in cubit, stopping recording', 
              name: 'MeetingCubit');
            
            emit(state.copyWith(
              status: MeetingStateStatus.processingRecording,
              warningMessage: 'Processing recording...',
              processingMessage: 'Please wait while we process your recording...',
              remainingTime: null
            ));
            
            stopRecording(state.selectedMeeting!.id, isTimeLimit: true);
          }
        } else {
          // Check warnings in descending order of time
          final thresholds = [
            const Duration(minutes: 5), // First warning at 5 minutes remaining
            const Duration(minutes: 2), // Second warning at 2 minutes
            const Duration(minutes: 1), // Third warning at 1 minute
            const Duration(seconds: 30), // 30 seconds warning
            const Duration(seconds: 10), // Final countdown
          ];

          for (final threshold in thresholds) {
            if (shouldShowWarning(threshold)) {
              final minutes = threshold.inMinutes;
              final seconds = threshold.inSeconds % 60;
              warningMessage = 'Recording will stop in '
                '${minutes > 0 ? '$minutes minutes ' : ''}'
                '${seconds > 0 ? '$seconds seconds' : ''}';
              break; // Only show one warning at a time
            }
          }
        }

        // Update remaining time and warning message if needed
        if (!isClosed) {
          emit(state.copyWith(
            remainingTime: duration,
            warningMessage: warningMessage
          ));
        }
      },
      onError: (error) {
        dev.log('Error in timer subscription: $error', 
          name: 'MeetingCubit',
          error: error
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> _handleUploadLater() async {
    try {
      dev.log('Handling upload later', name: 'MeetingCubit');
      if (state.currentRecording != null) {
        // Just update state since recording is already saved
        emit(state.copyWith(
          status: MeetingStateStatus.loaded,
          currentRecording: null,
          currentRecordingPath: null,
          warningMessage: null,
          remainingTime: null,
          error: null,
        ));
        
        // Reload pending recordings to show the saved recording
        final pending = await _storage.getPendingRecordings();
        emit(state.copyWith(pendingRecordings: pending));
        
        dev.log('Recording marked for later upload', name: 'MeetingCubit');
      }
    } catch (e) {
      dev.log('Error handling upload later: $e', name: 'MeetingCubit');
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: 'Failed to handle upload later: $e',
      ));
    }
  }

  Future<void> handleRecordingState(String meetingId, RecordingAction action) async {
    try {
      final recordingManager = GetIt.I<RecordingManager>();
      final meeting = state.selectedMeeting;

      switch (action) {
        case RecordingAction.start:
          emit(state.copyWith(
            status: MeetingStateStatus.loading,
            warningMessage: null,
            error: null,
          ));
          await startRecording(meetingId);
          break;
          
        case RecordingAction.stop:
          emit(state.copyWith(
            status: MeetingStateStatus.processingRecording,
            processingMessage: 'Stopping recording...',
            warningMessage: null,
            error: null,
          ));

          final metadata = await recordingManager.stopRecording(
            meetingId,
            state.currentRecordingPath!,
            meetingTitle: meeting?.title,
          );

          emit(state.copyWith(
            status: MeetingStateStatus.recordingStopped,
            currentRecordingPath: metadata.filePath,
            currentRecording: metadata,
            recordingDuration: metadata.duration,
            warningMessage: null,
            error: null,
          ));
          break;
          
        case RecordingAction.pause:
          await pauseRecording();
          break;
          
        case RecordingAction.resume:
          await resumeRecording();
          break;
          
        case RecordingAction.upload:
          if (state.currentRecording != null) {
            await uploadRecording(state.currentRecording!);
          }
          break;
          
        case RecordingAction.saveForLater:
          await _handleUploadLater();
          break;
          
        case RecordingAction.discard:
          if (state.currentRecording != null) {
            emit(state.copyWith(
              status: MeetingStateStatus.loading,
              warningMessage: 'Discarding recording...',
              error: null,
            ));
            await deleteRecording(state.currentRecording!.meetingId);
            emit(state.copyWith(
              status: MeetingStateStatus.loaded,
              currentRecording: null,
              currentRecordingPath: null,
              warningMessage: null,
              remainingTime: null,
              error: null,
            ));
          }
          break;
      }
    } catch (e) {
      dev.log('Error handling recording state: $e', name: 'MeetingCubit');
      emit(state.copyWith(
        status: MeetingStateStatus.recordingFailed,
        error: 'Failed to handle recording: $e',
        warningMessage: null,
      ));
    }
  }

  Future<void> startRecording(String meetingId) async {
    try {
      // Clear any existing warning messages when starting new recording
      emit(state.copyWith(
        status: MeetingStateStatus.loading,
        warningMessage: null,
        error: null,
        currentRecordingPath: null // Explicitly clear any existing path
      ));
      
      // Ensure recorder is initialized
      if (!await _recordingManager.ensureInitialized()) {
        throw Exception('Failed to initialize recorder');
      }
      
      final path = await _recordingManager.startRecording(meetingId);
      dev.log('Recording started, path: $path', name: 'MeetingCubit');
      
      emit(state.copyWith(
        status: MeetingStateStatus.recording,
        currentRecordingPath: path,
        warningMessage: null,
        error: null,
      ));
      
      _handleRecordingTimer(); // Start listening to timer updates
    } catch (e) {
      dev.log('Error starting recording: $e', name: 'MeetingCubit');
      emit(state.copyWith(
        status: MeetingStateStatus.recordingFailed,
        error: e.toString(),
        currentRecordingPath: null, // Ensure path is cleared on error
        warningMessage: null,
      ));
      
      // Ensure cleanup on error
      try {
        await _recordingManager.cleanup();
      } catch (cleanupError) {
        dev.log('Error during cleanup: $cleanupError', 
          name: 'MeetingCubit',
          error: cleanupError
        );
      }
    }
  }

  Future<void> stopRecording(String meetingId, {bool isTimeLimit = false}) async {
    try {
      // Only emit loading state if not already processing (time limit case)
      if (!isTimeLimit) {
        emit(state.copyWith(
          status: MeetingStateStatus.processingRecording,
          processingMessage: 'Stopping recording...',
          warningMessage: null,
          error: null,
        ));
      }
      
      if (state.currentRecordingPath == null) {
        throw Exception('No active recording found');
      }

      final metadata = await _recordingManager.stopRecording(
        meetingId, 
        state.currentRecordingPath!,
        isTimeLimit: isTimeLimit,
        meetingTitle: state.selectedMeeting?.title,
      );

      emit(state.copyWith(
        status: MeetingStateStatus.recordingStopped,
        currentRecordingPath: null,
        currentRecording: metadata,
        warningMessage: null,
        error: null,
      ));
    } catch (e) {
      dev.log('Error stopping recording: $e', name: 'MeetingCubit');
      emit(state.copyWith(
        status: MeetingStateStatus.recordingFailed,
        error: e.toString(),
        warningMessage: null,
      ));
    }
  }

  // Add this method to reset warning state when needed
  void _resetWarningState() {
    _lastWarningThreshold = null;
  }

  // Update the cleanup method to reset warning state
  void cleanupRecordingState() {
    try {
      dev.log('Cleaning up recording state', name: 'MeetingCubit');
      
      _resetWarningState();
      _timerSubscription?.cancel();
      _timerSubscription = null;
      _uploadCancelToken?.cancel();
      
      // Clean up recording manager
      _recordingManager.cleanup().catchError((e) {
        dev.log('Error during recording manager cleanup: $e',
          name: 'MeetingCubit',
          error: e
        );
      });
      
      if (!isClosed) {  // Check if cubit is still active
        emit(state.copyWith(
          status: MeetingStateStatus.initial,
          currentRecording: null,
          currentRecordingPath: null,
          warningMessage: null,
          remainingTime: null,
          error: null,
        ));
      }
    } catch (e) {
      dev.log('Error cleaning up recording state: $e',
        name: 'MeetingCubit',
        error: e
      );
    }
  }

  Future<void> cancelUpload() async {
    try {
      // Cancel upload manager first
      await _uploadManager.cancelUpload();
      
      // Cancel subscriptions immediately to prevent any further updates
      await _uploadProgressSubscription?.cancel();
      await _uploadStatusSubscription?.cancel();
      _uploadProgressSubscription = null;
      _uploadStatusSubscription = null;
      
      // If we have a current recording being uploaded, update its status
      if (state.currentRecording != null) {
        final cancelledRecording = state.currentRecording!.copyWith(
          status: RecordingUploadStatus.failed,
          uploadProgress: 0,
        );
        await _storage.updateRecording(cancelledRecording);
        
        // Update pending recordings list
        final currentRecordings = List<RecordingMetadata>.from(state.pendingRecordings ?? []);
        final recordingIndex = currentRecordings.indexWhere((r) => r.id == cancelledRecording.id);
        if (recordingIndex != -1) {
          currentRecordings[recordingIndex] = cancelledRecording;
        }
        
        // Emit a single state update with all changes
        emit(state.copyWith(
          status: MeetingStateStatus.uploadCancelled, // Add this state to your enum
          isAudioUploading: false,
          audioUploadProgress: null,
          currentRecording: null,
          pendingRecordings: currentRecordings,
          error: null, // Clear any existing error
        ));
      } else {
        // Even without a current recording, update the state
        emit(state.copyWith(
          status: MeetingStateStatus.uploadCancelled,
          isAudioUploading: false,
          audioUploadProgress: null,
          error: null,
        ));
      }
    } catch (e) {
      dev.log('Error cancelling upload: $e',
        name: 'MeetingCubit',
        error: e
      );
      // Emit error state but still ensure upload flags are reset
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        isAudioUploading: false,
        audioUploadProgress: null,
        error: 'Error cancelling upload: $e',
      ));
    }
  }

  Future<void> uploadRecording(RecordingMetadata recording) async {
    try {
      // Cancel any existing upload and subscriptions
      await _uploadProgressSubscription?.cancel();
      await _uploadStatusSubscription?.cancel();
      _uploadProgressSubscription = null;
      _uploadStatusSubscription = null;
      
      // Update recording status to uploading
      final updatedRecording = recording.copyWith(
        status: RecordingUploadStatus.uploading,
        uploadProgress: 0,
        uploadAttempts: recording.uploadAttempts + 1,
        lastUploadAttempt: DateTime.now(),
      );
      await _storage.updateRecording(updatedRecording);

      // Update state with the new recording
      final pendingRecordings = List<RecordingMetadata>.from(state.pendingRecordings ?? []);
      final index = pendingRecordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) {
        pendingRecordings[index] = updatedRecording;
      }
      
      // Emit initial upload state
      emit(state.copyWith(
        status: MeetingStateStatus.uploading,
        isAudioUploading: true,
        audioUploadProgress: 0,
        currentRecording: updatedRecording,
        pendingRecordings: pendingRecordings,
        error: null,
      ));

      // Subscribe to upload progress
      _uploadProgressSubscription = _uploadManager.progress.listen(
        (progress) async {
          if (!isClosed) {  // Check if cubit is still active
            final progressRecording = updatedRecording.copyWith(uploadProgress: progress);
            await _storage.updateRecording(progressRecording);

            final currentRecordings = List<RecordingMetadata>.from(state.pendingRecordings ?? []);
            final recordingIndex = currentRecordings.indexWhere((r) => r.id == recording.id);
            if (recordingIndex != -1) {
              currentRecordings[recordingIndex] = progressRecording;
            }
            
            emit(state.copyWith(
              audioUploadProgress: progress,
              isAudioUploading: true,
              currentRecording: progressRecording,
              pendingRecordings: currentRecordings,
            ));
          }
        },
        onError: (error) {
          dev.log('Error in upload progress stream: $error',
            name: 'MeetingCubit',
            error: error
          );
        },
      );

      // Subscribe to upload status
      _uploadStatusSubscription = _uploadManager.status.listen(
        (status) async {
          if (!isClosed) {  // Check if cubit is still active
            if (status == 'Upload completed successfully') {
              await _handleUploadSuccess(updatedRecording);
            } else if (status?.startsWith('Upload failed') ?? false) {
              await _handleUploadFailure(updatedRecording, status);
            }
          }
        },
        onError: (error) {
          dev.log('Error in upload status stream: $error',
            name: 'MeetingCubit',
            error: error
          );
        },
      );

      // Start upload
      await _uploadManager.startUpload(recording);
    } catch (e) {
      dev.log('Error uploading recording: $e',
        name: 'MeetingCubit',
        error: e
      );
      await _handleUploadFailure(recording, e.toString());
    }
  }

  Future<void> _handleUploadSuccess(RecordingMetadata recording) async {
    try {
      // Update recording status to completed
      final completedRecording = recording.copyWith(
        status: RecordingUploadStatus.completed,
        uploadProgress: 1.0,
      );
      await _storage.updateRecording(completedRecording);

      // Remove from pending recordings
      final remainingRecordings = List<RecordingMetadata>.from(state.pendingRecordings ?? [])
        ..removeWhere((r) => r.id == recording.id);

      // Cancel subscriptions
      await _uploadProgressSubscription?.cancel();
      await _uploadStatusSubscription?.cancel();
      _uploadProgressSubscription = null;
      _uploadStatusSubscription = null;

      emit(state.copyWith(
        status: MeetingStateStatus.uploadCompleted,
        isAudioUploading: false,
        audioUploadProgress: 1.0,
        currentRecording: null,
        pendingRecordings: remainingRecordings,
        error: null,
      ));
    } catch (e) {
      dev.log('Error handling upload success: $e',
        name: 'MeetingCubit',
        error: e
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        error: 'Error finalizing upload: $e',
      ));
    }
  }

  Future<void> _handleUploadFailure(RecordingMetadata recording, String? errorMessage) async {
    try {
      // Update recording status to failed
      final failedRecording = recording.copyWith(
        status: RecordingUploadStatus.failed,
        uploadProgress: 0,
      );
      await _storage.updateRecording(failedRecording);

      // Update state with failed recording
      final currentRecordings = List<RecordingMetadata>.from(state.pendingRecordings ?? []);
      final recordingIndex = currentRecordings.indexWhere((r) => r.id == recording.id);
      if (recordingIndex != -1) {
        currentRecordings[recordingIndex] = failedRecording;
      }

      // Cancel subscriptions
      await _uploadProgressSubscription?.cancel();
      await _uploadStatusSubscription?.cancel();
      _uploadProgressSubscription = null;
      _uploadStatusSubscription = null;

      emit(state.copyWith(
        status: MeetingStateStatus.error,
        isAudioUploading: false,
        audioUploadProgress: 0,
        currentRecording: null,
        pendingRecordings: currentRecordings,
        error: errorMessage ?? 'Upload failed',
      ));
    } catch (e) {
      dev.log('Error handling upload failure: $e',
        name: 'MeetingCubit',
        error: e
      );
      emit(state.copyWith(
        status: MeetingStateStatus.error,
        isAudioUploading: false,
        audioUploadProgress: 0,
        error: 'Error handling upload failure: $e',
      ));
    }
  }

  Future<void> loadPendingRecordings() async {
    try {
      final pending = await _storage.getPendingRecordings();
      emit(state.copyWith(pendingRecordings: pending));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load pending recordings: $e',
      ));
    }
  }

  Future<void> deletePendingRecording(String meetingId) async {
    try {
      await _storage.deleteRecording(meetingId);
      
      // Clear recording state if this was the current recording
      if (state.currentRecordingPath != null && 
          state.selectedMeeting?.id == meetingId) {
        cleanupRecordingState();
      }
      
      // Reload pending recordings to update the list
      await loadPendingRecordings();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteRecording(String meetingId) async {
    try {
      await _storage.deleteRecording(meetingId);
      
      // Clear recording state if this was the current recording
      if (state.currentRecordingPath != null && 
          state.selectedMeeting?.id == meetingId) {
        cleanupRecordingState();
      }
      
      // Reload pending recordings to update the list
      await loadPendingRecordings();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> pauseRecording() async {
    try {
      dev.log(state.currentRecordingPath ?? 'No recording path', name: 'MeetingCubit');
      await _recordingManager.pauseRecording();
      emit(state.copyWith(
        status: MeetingStateStatus.recordingPaused,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.recordingFailed,
        error: e.toString(),
      ));
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recordingManager.resumeRecording();
      emit(state.copyWith(
        status: MeetingStateStatus.recording,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MeetingStateStatus.recordingFailed,
        error: e.toString(),
      ));
    }
  }
}