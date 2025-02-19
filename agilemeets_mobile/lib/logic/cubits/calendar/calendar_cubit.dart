import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/calendar_repository.dart';
import 'calendar_state.dart';
import 'dart:developer' as developer;

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository _calendarRepository;

  CalendarCubit({
    required CalendarRepository calendarRepository,
  })  : _calendarRepository = calendarRepository,
        super(const CalendarState());

  Future<String> getCalendarFeedUrl({String? projectId}) async {
    try {
      emit(state.copyWith(
        status: CalendarStateStatus.loading,
        error: null,
      ));

      final feedUrl = projectId != null
          ? await _calendarRepository.getProjectCalendarFeedUrl(projectId)
          : await _calendarRepository.getPersonalCalendarFeedUrl();
      
      emit(state.copyWith(
        status: CalendarStateStatus.loaded,
        feedUrl: feedUrl,
      ));
      return feedUrl;
    } catch (e) {
      developer.log(
        'Error getting calendar feed URL',
        error: e,
        name: 'CalendarCubit',
      );
      emit(state.copyWith(
        status: CalendarStateStatus.error,
        error: 'Failed to get calendar feed. Please try again.',
      ));
      rethrow;
    }
  }

  void reset() {
    emit(const CalendarState());
  }
} 