import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/enums/meeting_status.dart';

class ModifyRecurringMeetingDTO {
  final bool applyToSeries;
  final String? title;
  final String? goal;
  final MeetingLanguage? language;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? timeZone;
  final String? location;
  final DateTime? reminderTime;
  final MeetingStatus? status;
  final List<String>? addMembers;
  final List<String>? removeMembers;

  const ModifyRecurringMeetingDTO({
    required this.applyToSeries,
    this.title,
    this.goal,
    this.language,
    this.startTime,
    this.endTime,
    this.timeZone,
    this.location,
    this.reminderTime,
    this.status,
    this.addMembers,
    this.removeMembers,
  });

  Map<String, dynamic> toJson() => {
    'applyToSeries': applyToSeries,
    if (title != null) 'title': title,
    if (goal != null) 'goal': goal,
    if (language != null) 'language': language?.value,
    if (startTime != null) 'startTime': startTime?.toIso8601String(),
    if (endTime != null) 'endTime': endTime?.toIso8601String(),
    if (timeZone != null) 'timeZone': timeZone,
    if (location != null) 'location': location,
    if (reminderTime != null) 'reminderTime': reminderTime?.toIso8601String(),
    if (status != null) 'status': status?.value,
    if (addMembers != null) 'addMembers': addMembers,
    if (removeMembers != null) 'removeMembers': removeMembers,
  };
} 