import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:agilemeets/data/models/meeting_details_dto.dart';
import 'package:agilemeets/data/models/grouped_meetings_response.dart';
import 'package:agilemeets/data/models/meeting_ai_report_dto.dart';
import 'package:agilemeets/data/models/join_meeting_response.dart';
import 'package:agilemeets/data/models/recording_metadata.dart';

part 'meeting_state.freezed.dart';

enum MeetingStateStatus {
  initial,
  loading,
  loaded,
  error,
  creating,
  created,
  updating,
  updated,
  validationError,
  joiningMeeting,
  joinedMeeting,
  loadingAIReport,
  aiReportLoaded,
  recording,
  recordingPaused,
  recordingStopped,
  recordingFailed,
  processingRecording,
  uploading,
  uploadCompleted,
  uploadCancelled,
}

@freezed
class MeetingState with _$MeetingState {
  const factory MeetingState({
    @Default(MeetingStateStatus.initial) MeetingStateStatus status,
    List<MeetingGroupDTO>? groups,
    MeetingDetailsDTO? selectedMeeting,
    String? error,
    List<ValidationError>? validationErrors,
    @Default(false) bool isAudioUploading,
    double? audioUploadProgress,
    String? audioUrl,
    @Default(false) bool hasMore,
    String? lastMeetingId,
    String? pastLastMeetingId,
    String? upcomingLastMeetingId,
    DateTime? pastReferenceDate,
    DateTime? pastNextReferenceDate,
    DateTime? upcomingReferenceDate,
    DateTime? upcomingNextReferenceDate,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRefreshing,
    MeetingAIReportDTO? aiReport,
    JoinMeetingResponse? joinMeetingResponse,
    String? timeZoneId,
    @Default(0) int totalMeetingsCount,
    String? currentRecordingPath,
    RecordingMetadata? currentRecording,
    List<RecordingMetadata>? pendingRecordings,
    Duration? recordingDuration,
    String? warningMessage,
    Duration? remainingTime,
    String? processingMessage,
  }) = _MeetingState;
}