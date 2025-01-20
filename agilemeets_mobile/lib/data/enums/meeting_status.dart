import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum MeetingStatus {
  scheduled(0),
  inProgress(1),
  completed(2),
  cancelled(3);

  final int value;
  const MeetingStatus(this.value);

  factory MeetingStatus.fromInt(int value) {
    return MeetingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MeetingStatus.scheduled,
    );
  }

  String get label {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.inProgress:
        return 'In Progress';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case MeetingStatus.scheduled:
        return AppTheme.infoBlue;
      case MeetingStatus.inProgress:
        return AppTheme.warningOrange;
      case MeetingStatus.completed:
        return AppTheme.successGreen;
      case MeetingStatus.cancelled:
        return AppTheme.errorRed;
    }
  }
} 