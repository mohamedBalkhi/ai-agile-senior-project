import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/timezone_repository.dart';
import 'timezone_state.dart';
import 'dart:developer' as developer;

class TimeZoneCubit extends Cubit<TimeZoneState> {
  final TimeZoneRepository _repository;

  TimeZoneCubit(this._repository) : super(const TimeZoneState());

  Future<void> loadCommonTimezones() async {
    try {
      emit(state.copyWith(status: TimeZoneStateStatus.loading));

      final timezones = await _repository.getCommonTimezones();
      
      emit(state.copyWith(
        status: TimeZoneStateStatus.loaded,
        timezones: timezones,
      ));
    } catch (e) {
      developer.log(
        'Error loading timezones: $e',
        name: 'TimeZoneCubit',
        error: e,
      );
      emit(state.copyWith(
        status: TimeZoneStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadAllTimezones() async {
    try {
      emit(state.copyWith(status: TimeZoneStateStatus.loading));

      final timezones = await _repository.getAllTimezones();
      
      emit(state.copyWith(
        status: TimeZoneStateStatus.loaded,
        timezones: timezones,
      ));
    } catch (e) {
      developer.log(
        'Error loading timezones: $e',
        name: 'TimeZoneCubit',
        error: e,
      );
      emit(state.copyWith(
        status: TimeZoneStateStatus.error,
        error: e.toString(),
      ));
    }
  }
} 