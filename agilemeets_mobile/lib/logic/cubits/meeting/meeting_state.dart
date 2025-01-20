import 'package:equatable/equatable.dart';
import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/models/meeting_details_dto.dart';
import 'package:agilemeets/data/models/grouped_meetings_response.dart';
import 'package:agilemeets/data/models/meeting_ai_report_dto.dart';

enum MeetingStateStatus {
  initial,
  loading,
  loaded,
  creating,
  created,
  updating,
  updated,
  error,
  validationError,
  loadingAIReport,
  aiReportLoaded,
}

class MeetingState extends Equatable {
  final MeetingStateStatus status;
  final List<MeetingGroupDTO>? groups;
  final MeetingDetailsDTO? selectedMeeting;
  final String? error;
  final List<ValidationError>? validationErrors;
  final bool isAudioUploading;
  final double? audioUploadProgress;
  final String? audioUrl;
  final bool hasMorePast;
  final bool hasMoreFuture;
  final DateTime? oldestMeetingDate;
  final DateTime? newestMeetingDate;
  final bool isLoadingMore;
  final bool isRefreshing;
  final MeetingAIReportDTO? aiReport;

  const MeetingState({
    this.status = MeetingStateStatus.initial,
    this.groups,
    this.selectedMeeting,
    this.error,
    this.validationErrors,
    this.isAudioUploading = false,
    this.audioUploadProgress,
    this.audioUrl,
    this.hasMorePast = false,
    this.hasMoreFuture = false,
    this.oldestMeetingDate,
    this.newestMeetingDate,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.aiReport,
  });

  MeetingState copyWith({
    MeetingStateStatus? status,
    List<MeetingGroupDTO>? groups,
    MeetingDetailsDTO? selectedMeeting,
    String? error,
    List<ValidationError>? validationErrors,
    bool? isAudioUploading,
    double? audioUploadProgress,
    String? audioUrl,
    bool? hasMorePast,
    bool? hasMoreFuture,
    DateTime? oldestMeetingDate,
    DateTime? newestMeetingDate,
    bool? isLoadingMore,
    bool? isRefreshing,
    MeetingAIReportDTO? aiReport,
  }) {
    return MeetingState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedMeeting: selectedMeeting ?? this.selectedMeeting,
      error: error,
      validationErrors: validationErrors,
      isAudioUploading: isAudioUploading ?? this.isAudioUploading,
      audioUploadProgress: audioUploadProgress ?? this.audioUploadProgress,
      audioUrl: audioUrl ?? this.audioUrl,
      hasMorePast: hasMorePast ?? this.hasMorePast,
      hasMoreFuture: hasMoreFuture ?? this.hasMoreFuture,
      oldestMeetingDate: oldestMeetingDate ?? this.oldestMeetingDate,
      newestMeetingDate: newestMeetingDate ?? this.newestMeetingDate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      aiReport: aiReport ?? this.aiReport,
    );
  }

  @override
  List<Object?> get props => [
        status,
        groups,
        selectedMeeting,
        error,
        validationErrors,
        isAudioUploading,
        audioUploadProgress,
        audioUrl,
        hasMorePast,
        hasMoreFuture,
        oldestMeetingDate,
        newestMeetingDate,
        isLoadingMore,
        isRefreshing,
        aiReport,
      ];
}