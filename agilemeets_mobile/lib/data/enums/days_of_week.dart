class DaysOfWeek {
  static const none = DaysOfWeek(0);
  static const sunday = DaysOfWeek(1);
  static const monday = DaysOfWeek(2);
  static const tuesday = DaysOfWeek(4);
  static const wednesday = DaysOfWeek(8);
  static const thursday = DaysOfWeek(16);
  static const friday = DaysOfWeek(32);
  static const saturday = DaysOfWeek(64);

  final int value;
  const DaysOfWeek(this.value);

  bool contains(DaysOfWeek day) => (value & day.value) != 0;

  static List<String> getSelectedDays(DaysOfWeek value) {
    final days = <String>[];
    if (value.contains(sunday)) days.add('Sunday');
    if (value.contains(monday)) days.add('Monday');
    if (value.contains(tuesday)) days.add('Tuesday');
    if (value.contains(wednesday)) days.add('Wednesday');
    if (value.contains(thursday)) days.add('Thursday');
    if (value.contains(friday)) days.add('Friday');
    if (value.contains(saturday)) days.add('Saturday');
    return days;
  }

  static DaysOfWeek combine(List<DaysOfWeek> days) {
    return DaysOfWeek(days.fold(0, (prev, day) => prev | day.value));
  }

  factory DaysOfWeek.fromInt(int value) {
    return DaysOfWeek(value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DaysOfWeek && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}