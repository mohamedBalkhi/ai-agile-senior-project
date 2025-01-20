import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum RequirementStatus {
  newOne(0),
  inProgress(1),
  completed(2);

  final int value;
  const RequirementStatus(this.value);

  factory RequirementStatus.fromInt(int value) {
    return RequirementStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RequirementStatus.newOne,
    );
  }

  String get label {
    switch (this) {
      case RequirementStatus.newOne:
        return 'New';
      case RequirementStatus.inProgress:
        return 'In Progress';
      case RequirementStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case RequirementStatus.newOne:
        return AppTheme.warningOrange;
      case RequirementStatus.inProgress:
        return AppTheme.progressBlue;
      case RequirementStatus.completed:
        return AppTheme.successGreen;
    }
  }
} 