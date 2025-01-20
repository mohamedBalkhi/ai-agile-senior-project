import '../enums/recurrence_type.dart';
import '../enums/days_of_week.dart';

class RecurringMeetingPatternDTO {
  final RecurrenceType recurrenceType;
  final int interval;
  final DateTime recurringEndDate;
  final int daysOfWeek;

  const RecurringMeetingPatternDTO({
    required this.recurrenceType,
    required this.interval,
    required this.recurringEndDate,
    required this.daysOfWeek,
  });

  factory RecurringMeetingPatternDTO.fromJson(Map<String, dynamic> json) {
    return RecurringMeetingPatternDTO(
      recurrenceType: RecurrenceType.fromInt(json['recurrenceType'] as int),
      interval: json['interval'] as int,
      recurringEndDate: DateTime.parse(json['recurringEndDate'] as String),
      daysOfWeek: json['daysOfWeek'] != null ? json['daysOfWeek'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'recurrenceType': recurrenceType.value,
    'interval': interval,
    'recurringEndDate': recurringEndDate.toIso8601String(),
    'daysOfWeek': daysOfWeek,
  };

  List<String> getSelectedDays() => DaysOfWeek.getSelectedDays(DaysOfWeek(daysOfWeek));
} 