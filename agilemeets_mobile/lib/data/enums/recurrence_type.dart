enum RecurrenceType {
  daily(0),
  weekly(1),
  monthly(2);

  final int value;
  const RecurrenceType(this.value);

  factory RecurrenceType.fromInt(int value) {
    return RecurrenceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecurrenceType.daily,
    );
  }

  String get label {
    switch (this) {
      case RecurrenceType.daily:
        return 'Every Day';
      case RecurrenceType.weekly:
        return 'Every Week';
      case RecurrenceType.monthly:
        return 'Every Month';
    }
  }

  String get description {
    switch (this) {
      case RecurrenceType.daily:
        return 'Meeting will repeat every day';
      case RecurrenceType.weekly:
        return 'Meeting will repeat on selected days every week';
      case RecurrenceType.monthly:
        return 'Meeting will repeat on the same date every month';
    }
  }
} 