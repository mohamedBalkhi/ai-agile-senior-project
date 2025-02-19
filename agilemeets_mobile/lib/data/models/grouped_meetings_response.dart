import 'package:agilemeets/data/models/meeting_dto.dart';

class GroupedMeetingsResponse {
  final List<MeetingGroupDTO> groups;
  final bool hasMore;
  final String? lastMeetingId;
  final String? referenceDate;
  final String? nextReferenceDate;
  final int totalMeetingsCount;

  const GroupedMeetingsResponse({
    required this.groups,
    required this.hasMore,
    this.lastMeetingId,
    this.referenceDate,
    this.nextReferenceDate,
    required this.totalMeetingsCount,
  });

  factory GroupedMeetingsResponse.fromJson(Map<String, dynamic> json) {
    return GroupedMeetingsResponse(
      groups: (json['groups'] as List)
          .map((e) => MeetingGroupDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool,
      lastMeetingId: json['lastMeetingId'] as String?,
      referenceDate: json['referenceDate'] as String?,
      nextReferenceDate: json['nextReferenceDate'] as String?,
      totalMeetingsCount: json['totalMeetingsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'groups': groups.map((e) => e.toJson()).toList(),
    'hasMore': hasMore,
    'lastMeetingId': lastMeetingId,
    'referenceDate': referenceDate,
    'nextReferenceDate': nextReferenceDate,
    'totalMeetingsCount': totalMeetingsCount,
  };
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
      date: DateTime.parse(json['date'] as String).toLocal(),
      meetings: (json['meetings'] as List)
          .map((e) => MeetingDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'groupTitle': groupTitle,
    'date': date.toIso8601String(),
    'meetings': meetings.map((e) => e.toJson()).toList(),
  };

  MeetingGroupDTO copyWith({
    String? groupTitle,
    DateTime? date,
    List<MeetingDTO>? meetings,
  }) {
    return MeetingGroupDTO(
      groupTitle: groupTitle ?? this.groupTitle,
      date: date ?? this.date,
      meetings: meetings ?? this.meetings,
    );
  }
}