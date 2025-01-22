import 'dart:io';

import 'package:agilemeets/data/enums/days_of_week.dart';
import 'package:agilemeets/data/enums/meeting_language.dart';
import 'package:agilemeets/data/enums/meeting_type.dart';
import 'package:agilemeets/data/enums/recurrence_type.dart';

class CreateMeetingForm {
  String? title;
  String? goal;
  MeetingLanguage language;
  MeetingType type;
  DateTime? startTime;
  DateTime? endTime;
  String? timeZoneId;
  String projectId;
  List<String> memberIds;
  String? location;
  String? meetingUrl;
  DateTime? reminderTime;
  bool isRecurring;
  RecurringMeetingPattern? recurringPattern;
  File? audioFile;

  CreateMeetingForm({
    this.title,
    this.goal,
    this.language = MeetingLanguage.english,
    this.type = MeetingType.inPerson,
    this.startTime,
    this.endTime,
    this.timeZoneId,
    required this.projectId,
    this.memberIds = const [],
    this.location,
    this.meetingUrl,
    this.reminderTime,
    this.isRecurring = false,
    this.recurringPattern,
    this.audioFile,
  });

  bool get isValid {
    if (title?.isEmpty ?? true) return false;
    if (startTime == null || endTime == null) return false;
    if (startTime!.isAfter(endTime!)) return false;
    if (timeZoneId?.isEmpty ?? true) return false;
    if (memberIds.isEmpty) return false;
    
    // Type-specific validation
    switch (type) {
      case MeetingType.inPerson:
        if (location?.isEmpty ?? true) return false;
        break;
      case MeetingType.done:
        if (audioFile == null) return false;
        break;
      case MeetingType.online:
        // Online meetings not implemented yet
        return true;
    }

    if (isRecurring && recurringPattern == null) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Goal': goal,
      'Language': language.value,
      'Type': type.value,
      'StartTime': startTime?.toIso8601String(),
      'EndTime': endTime?.toIso8601String(),
      'TimeZone': timeZoneId,
      'ProjectId': projectId,
      'MemberIds': memberIds,
      'Location': location,
      'MeetingUrl': meetingUrl,
      'ReminderTime': reminderTime?.toIso8601String(),
      'IsRecurring': isRecurring,
      if (isRecurring && recurringPattern != null) ...{
        'RecurringPattern.RecurrenceType': recurringPattern!.recurrenceType.value,
        'RecurringPattern.Interval': recurringPattern!.interval,
        'RecurringPattern.RecurringEndDate': 
            recurringPattern!.recurringEndDate.toIso8601String(),
        'RecurringPattern.DaysOfWeek': recurringPattern!.daysOfWeek.value,
      },
    };
  }
}

class RecurringMeetingPattern {
  RecurrenceType recurrenceType;
  int interval;
  DateTime recurringEndDate;
  DaysOfWeek daysOfWeek;

  RecurringMeetingPattern({
    this.recurrenceType = RecurrenceType.daily,
    this.interval = 1,
    required this.recurringEndDate,
    this.daysOfWeek = const DaysOfWeek(0),
  });
}