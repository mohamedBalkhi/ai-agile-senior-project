enum MeetingLanguage {
  english(0),
  arabic(1);

  final int value;
  const MeetingLanguage(this.value);

  factory MeetingLanguage.fromInt(int value) {
    return MeetingLanguage.values.firstWhere(
      (lang) => lang.value == value,
      orElse: () => MeetingLanguage.english,
    );
  }

  String get label {
    switch (this) {
      case MeetingLanguage.english:
        return 'English';
      case MeetingLanguage.arabic:
        return 'Arabic';
    }
  }
} 