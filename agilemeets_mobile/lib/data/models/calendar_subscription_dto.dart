import 'package:equatable/equatable.dart';

enum CalendarFeedType {
  personal,    // All user's meetings
  project,     // Project meetings
  series       // Specific recurring series
}

class CreateCalendarSubscriptionDTO extends Equatable {
  final CalendarFeedType feedType;
  final String? projectId;
  final String? recurringPatternId;
  final int expirationDays;
  final String? timeZoneId;
  const CreateCalendarSubscriptionDTO({
    required this.feedType,
    this.projectId,
    this.recurringPatternId,
    this.timeZoneId,
    this.expirationDays = 365, // Default to 365 days
  });

  Map<String, dynamic> toJson() => {
    'feedType': feedType.index,
    'projectId': projectId,
    'recurringPatternId': recurringPatternId,
    'expirationDays': expirationDays,
    'timeZoneId': timeZoneId,
  };

  @override
  List<Object?> get props => [feedType, projectId, recurringPatternId, expirationDays];
}

class CalendarSubscriptionDTO extends Equatable {
  final String? feedUrl;
  final DateTime expiresAt;
  final String? feedType;
  final String? projectName;
  final String? seriesTitle;

  const CalendarSubscriptionDTO({
    this.feedUrl,
    required this.expiresAt,
    this.feedType,
    this.projectName,
    this.seriesTitle,
  });

  factory CalendarSubscriptionDTO.fromJson(Map<String, dynamic> json) {
    return CalendarSubscriptionDTO(
      feedUrl: json['feedUrl'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      feedType: json['feedType'] as String?,
      projectName: json['projectName'] as String?,
      seriesTitle: json['seriesTitle'] as String?,
    );
  }

  @override
  List<Object?> get props => [feedUrl, expiresAt, feedType, projectName, seriesTitle];
} 