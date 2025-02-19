import 'package:equatable/equatable.dart';

enum CalendarStateStatus {
  initial,
  loading,
  loaded,
  error,
}

class CalendarState extends Equatable {
  final CalendarStateStatus status;
  final String? feedUrl;
  final String? error;

  const CalendarState({
    this.status = CalendarStateStatus.initial,
    this.feedUrl,
    this.error,
  });

  CalendarState copyWith({
    CalendarStateStatus? status,
    String? feedUrl,
    String? error,
  }) {
    return CalendarState(
      status: status ?? this.status,
      feedUrl: feedUrl ?? this.feedUrl,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, feedUrl, error];
}