import 'package:agilemeets/data/models/home_page_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:agilemeets/core/errors/validation_error.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final HomePageDTO? data;
  final String? error;
  final List<ValidationError>? validationErrors;
  final bool isRefreshing;

  const HomeState({
    this.status = HomeStatus.initial,
    this.data,
    this.error,
    this.validationErrors,
    this.isRefreshing = false,
  });

  HomeState copyWith({
    HomeStatus? status,
    HomePageDTO? data,
    String? error,
    List<ValidationError>? validationErrors,
    bool? isRefreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
      validationErrors: validationErrors,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        error,
        validationErrors,
        isRefreshing,
      ];
} 