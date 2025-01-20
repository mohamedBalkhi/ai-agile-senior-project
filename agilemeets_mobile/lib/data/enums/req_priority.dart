import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum ReqPriority {
  low(0),
  medium(1),
  high(2);

  final int value;
  const ReqPriority(this.value);

  factory ReqPriority.fromInt(int value) {
    return ReqPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReqPriority.low,
    );
  }

  String get label {
    switch (this) {
      case ReqPriority.low:
        return 'Low';
      case ReqPriority.medium:
        return 'Medium';
      case ReqPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case ReqPriority.low:
        return AppTheme.infoBlue;
      case ReqPriority.medium:
        return AppTheme.warningOrange;
      case ReqPriority.high:
        return AppTheme.errorRed;
    }
  }
} 