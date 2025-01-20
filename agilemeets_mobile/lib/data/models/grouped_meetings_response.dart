import 'package:agilemeets/data/models/meeting_dto.dart';

class GroupedMeetingsResponse {
  final List<MeetingGroupDTO> groups;
  final bool hasMorePast;
  final bool hasMoreFuture;
  final DateTime? oldestMeetingDate;
  final DateTime? newestMeetingDate;

  const GroupedMeetingsResponse({
    required this.groups,
    required this.hasMorePast,
    required this.hasMoreFuture,
    this.oldestMeetingDate,
    this.newestMeetingDate,
  });

  factory GroupedMeetingsResponse.fromJson(Map<String, dynamic> json) {
    return GroupedMeetingsResponse(
      groups: (json['groups'] as List)
          .map((e) => MeetingGroupDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMorePast: json['hasMorePast'] as bool,
      hasMoreFuture: json['hasMoreFuture'] as bool,
      oldestMeetingDate: json['oldestMeetingDate'] != null
          ? DateTime.parse(json['oldestMeetingDate'] as String)
          : null,
      newestMeetingDate: json['newestMeetingDate'] != null
          ? DateTime.parse(json['newestMeetingDate'] as String)
          : null,
    );
  }
}

class MeetingGroupDTO {
  final String groupTitle;
  final DateTime date;
  final List<MeetingDTO> meetings;

  const MeetingGroupDTO({
    required this.groupTitle,
    required this.date,
    required this.meetings,
  });

  factory MeetingGroupDTO.fromJson(Map<String, dynamic> json) {
    return MeetingGroupDTO(
      groupTitle: json['groupTitle'] as String,
      date: DateTime.parse(json['date'] as String),
      meetings: (json['meetings'] as List)
          .map((e) => MeetingDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
} 