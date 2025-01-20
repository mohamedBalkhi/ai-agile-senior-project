import 'package:flutter/material.dart';

enum MeetingType {
  inPerson(0),
  online(1),
  done(2);

  final int value;
  const MeetingType(this.value);

  factory MeetingType.fromInt(int value) {
    return MeetingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MeetingType.inPerson,
    );
  }

  String get label {
    switch (this) {
      case MeetingType.inPerson:
        return 'In Person';
      case MeetingType.online:
        return 'Online (Coming Soon)';
      case MeetingType.done:
        return 'Past Meeting';
    }
  }

  IconData get icon {
    switch (this) {
      case MeetingType.inPerson:
        return Icons.people;
      case MeetingType.online:
        return Icons.video_call;
      case MeetingType.done:
        return Icons.history;
    }
  }

  bool get isImplemented => this != MeetingType.online;
} 