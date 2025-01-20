import '../enums/meeting_language.dart';
import '../enums/meeting_type.dart';
import '../enums/meeting_status.dart';
import 'meeting_member_dto.dart';
import 'recurring_meeting_pattern_dto.dart';
import 'timezone_dto.dart';

class MeetingDetailsDTO {
  final String id;
  final String? title;
  final String? goal;
  final MeetingLanguage language;
  final MeetingType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? timeZoneId;
  final TimeZoneDTO timeZone;
  final String? location;
  final String? meetingUrl;
  final String? audioUrl;
  final DateTime? reminderTime;
  final MeetingStatus status;
  final MeetingMemberDTO? creator;
  final List<MeetingMemberDTO>? members;
  final bool isRecurring;
  final bool isRecurringInstance;
  final String? originalMeetingId;
  final RecurringMeetingPatternDTO? recurringPattern;
  final String? projectId;
  final String? projectName;
  const MeetingDetailsDTO({
    required this.id,
    this.title,
    this.goal,
    required this.language,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.timeZoneId,
    required this.timeZone,
    this.location,
    this.meetingUrl,
    this.audioUrl,
    this.reminderTime,
    required this.status,
    this.creator,
    this.members,
    required this.isRecurring,
    required this.isRecurringInstance,
    this.originalMeetingId,
    this.recurringPattern,
    this.projectId,
    this.projectName,
  });

  factory MeetingDetailsDTO.fromJson(Map<String, dynamic> json) {
    return MeetingDetailsDTO(
      id: json['id'] as String,
      title: json['title'] as String?,
      goal: json['goal'] as String?,
      language: MeetingLanguage.fromInt(json['language'] as int),
      type: MeetingType.fromInt(json['type'] as int),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      timeZoneId: json['timeZoneId'] as String?,
      timeZone: TimeZoneDTO.fromJson(json['timeZone'] as Map<String, dynamic>),
      location: json['location'] as String?,
      meetingUrl: json['meetingUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      reminderTime: json['reminderTime'] != null 
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      status: MeetingStatus.fromInt(json['status'] as int),
      creator: json['creator'] != null
          ? MeetingMemberDTO.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => MeetingMemberDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      isRecurring: json['isRecurring'] as bool,
      isRecurringInstance: json['isRecurringInstance'] as bool,
      originalMeetingId: json['originalMeetingId'] as String?,
      recurringPattern: json['recurringPattern'] != null
          ? RecurringMeetingPatternDTO.fromJson(
              json['recurringPattern'] as Map<String, dynamic>)
          : null,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'goal': goal,
    'language': language.value,
    'type': type.value,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'timeZoneId': timeZoneId,
    'timeZone': timeZone.toJson(),
    'location': location,
    'meetingUrl': meetingUrl,
    'audioUrl': audioUrl,
    'reminderTime': reminderTime?.toIso8601String(),
    'status': status.value,
    'creator': creator?.toJson(),
    'members': members?.map((e) => e.toJson()).toList(),
    'isRecurring': isRecurring,
    'isRecurringInstance': isRecurringInstance,
    'originalMeetingId': originalMeetingId,
    'recurringPattern': recurringPattern?.toJson(),
    'projectId': projectId,
    'projectName': projectName,
  };
} 