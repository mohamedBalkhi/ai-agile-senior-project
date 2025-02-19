import 'package:agilemeets/data/models/recurring_meeting_pattern_dto.dart';

import '../enums/meeting_type.dart';
import '../enums/meeting_status.dart';

class MeetingDTO {
  final String id;
  final String? title;
  final String? creatorId;
  final DateTime startTime;
  final DateTime endTime;
  final MeetingType type;
  final MeetingStatus status;
  final String? creatorName;
  final String? timeZoneId;
  final int memberCount;
  final bool isRecurring;
  final bool isRecurringInstance;
  final String? originalMeetingId;
  final RecurringMeetingPatternDTO? recurringPattern;
  final bool hasAudio;
  final String? projectId;
  final String? projectName;
  const MeetingDTO({
    required this.id,
    this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    this.creatorName,
    this.timeZoneId,
    required this.memberCount,
    required this.isRecurring,
    required this.isRecurringInstance,
    this.originalMeetingId,
    this.recurringPattern,
    required this.hasAudio,
    this.projectId,
    this.projectName,
    this.creatorId,
  });

  factory MeetingDTO.fromJson(Map<String, dynamic> json) {
    return MeetingDTO(
      id: json['id'] as String,
      title: json['title'] as String?,
      creatorId: json['creatorId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: MeetingType.fromInt(json['type'] as int),
      status: MeetingStatus.fromInt(json['status'] as int),
      creatorName: json['creatorName'] as String?,
      timeZoneId: json['timeZoneId'] as String?,
      memberCount: json['memberCount'] as int,
      isRecurring: json['isRecurring'] as bool,
      isRecurringInstance: json['isRecurringInstance'] as bool,
      originalMeetingId: json['originalMeetingId'] as String?,
      recurringPattern: json['recurringPattern'] != null
          ? RecurringMeetingPatternDTO.fromJson(json['recurringPattern'] as Map<String, dynamic>)
          : null,
      hasAudio: json['hasAudio'] as bool,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'type': type.value,
    'status': status.value,
    'creatorName': creatorName,
    'timeZoneId': timeZoneId,
    'memberCount': memberCount,
    'isRecurring': isRecurring,
    'isRecurringInstance': isRecurringInstance,
    'originalMeetingId': originalMeetingId,
    'hasAudio': hasAudio,
    'recurringPattern': recurringPattern?.toJson(),
    'projectId': projectId,
    'projectName': projectName,
  };
} 