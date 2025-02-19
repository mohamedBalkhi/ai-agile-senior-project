import 'package:hive/hive.dart';

part 'recording_metadata.g.dart';

@HiveType(typeId: 1)
enum RecordingUploadStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  compressing,

  @HiveField(2)
  uploading,

  @HiveField(3)
  failed,

  @HiveField(4)
  completed
}

@HiveType(typeId: 2)
class RecordingMetadata extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String meetingId;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime recordedAt;

  @HiveField(4)
  final DateTime expiresAt;

  @HiveField(5)
  final int fileSize;

  @HiveField(6)
  final Duration duration;

  @HiveField(7)
  final RecordingUploadStatus status;

  @HiveField(8)
  final double? uploadProgress;

  @HiveField(9)
  final int uploadAttempts;

  @HiveField(10)
  final DateTime? lastUploadAttempt;

  @HiveField(11)
  final bool wasTimeLimited;

  static const Duration defaultRetentionPeriod = Duration(days: 14);

  RecordingMetadata._({
    required this.id,
    required this.meetingId,
    required this.filePath,
    required this.recordedAt,
    required this.expiresAt,
    required this.fileSize,
    required this.duration,
    required this.status,
    this.uploadProgress,
    required this.uploadAttempts,
    this.lastUploadAttempt,
    required this.wasTimeLimited,
  });

  factory RecordingMetadata({
    required String id,
    required String meetingId,
    required String filePath,
    required DateTime recordedAt,
    DateTime? expiresAt,
    required int fileSize,
    required Duration duration,
    RecordingUploadStatus status = RecordingUploadStatus.pending,
    double? uploadProgress,
    int uploadAttempts = 0,
    DateTime? lastUploadAttempt,
    bool wasTimeLimited = false,
  }) {
    return RecordingMetadata._(
      id: id,
      meetingId: meetingId,
      filePath: filePath,
      recordedAt: recordedAt,
      expiresAt: expiresAt ?? recordedAt.add(defaultRetentionPeriod),
      fileSize: fileSize,
      duration: duration,
      status: status,
      uploadProgress: uploadProgress,
      uploadAttempts: uploadAttempts,
      lastUploadAttempt: lastUploadAttempt,
      wasTimeLimited: wasTimeLimited,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canRetry => status == RecordingUploadStatus.failed && uploadAttempts < 3;

  RecordingMetadata copyWith({
    String? id,
    String? meetingId,
    String? filePath,
    DateTime? recordedAt,
    DateTime? expiresAt,
    int? fileSize,
    Duration? duration,
    RecordingUploadStatus? status,
    double? uploadProgress,
    int? uploadAttempts,
    DateTime? lastUploadAttempt,
    bool? wasTimeLimited,
  }) {
    return RecordingMetadata._(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      filePath: filePath ?? this.filePath,
      recordedAt: recordedAt ?? this.recordedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadAttempts: uploadAttempts ?? this.uploadAttempts,
      lastUploadAttempt: lastUploadAttempt ?? this.lastUploadAttempt,
      wasTimeLimited: wasTimeLimited ?? this.wasTimeLimited,
    );
  }

  @override
  String toString() {
    return 'RecordingMetadata(id: $id, meetingId: $meetingId, status: $status, attempts: $uploadAttempts)';
  }
} 