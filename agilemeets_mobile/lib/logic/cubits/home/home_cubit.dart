import 'package:agilemeets/data/repositories/home_repository.dart';
import 'package:agilemeets/logic/cubits/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'dart:developer' as developer;

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({HomeRepository? homeRepository})
      : _repository = homeRepository ?? HomeRepository(),
        super(const HomeState());

  Future<void> loadHomePageData({bool refresh = false}) async {
    try {
      if (state.status == HomeStatus.loading && !refresh) {
        return;
      }

      emit(state.copyWith(
        status: HomeStatus.loading,
        error: null,
        isRefreshing: refresh,
      ));

      final response = await _repository.getHomePageData();
      
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(
          status: HomeStatus.loaded,
          data: response.data,
          error: null,
          isRefreshing: false,
        ));
      } else {
        emit(state.copyWith(
          status: HomeStatus.error,
          error: response.message ?? 'Failed to load home page data',
          isRefreshing: false,
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        validationErrors: e.errors,
        isRefreshing: false,
      ));
    } catch (e) {
      developer.log(
        'Error loading home page data: $e',
        name: 'HomeCubit',
        error: e,
      );
      emit(state.copyWith(
        status: HomeStatus.error,
        error: e.toString(),
        isRefreshing: false,
      ));
    }
  }
} 