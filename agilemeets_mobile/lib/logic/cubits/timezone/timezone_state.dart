import 'package:equatable/equatable.dart';
import '../../../data/models/timezone_dto.dart';

enum TimeZoneStateStatus {
  initial,
  loading,
  loaded,
  error,
}

class TimeZoneState extends Equatable {
  final TimeZoneStateStatus status;
  final List<TimeZoneDTO> timezones;
  final String? error;

  const TimeZoneState({
    this.status = TimeZoneStateStatus.initial,
    this.timezones = const [],
    this.error,
  });

  TimeZoneState copyWith({
    TimeZoneStateStatus? status,
    List<TimeZoneDTO>? timezones,
    String? error,
  }) {
    return TimeZoneState(
      status: status ?? this.status,
      timezones: timezones ?? this.timezones,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, timezones, error];
} 