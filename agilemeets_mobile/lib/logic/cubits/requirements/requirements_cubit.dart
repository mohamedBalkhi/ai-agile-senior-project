import 'package:agilemeets/data/enums/requirements_status.dart';
import 'package:agilemeets/data/models/requirements/project_requirements_dto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../data/repositories/requirements_repository.dart';
import '../../../data/exceptions/validation_exception.dart';
import '../../../data/models/requirements/requirements_filter.dart';
import '../../../data/models/requirements/add_req_manually_dto.dart';
import '../../../data/models/requirements/update_requirements_dto.dart';
import '../../../data/models/requirements/req_dto.dart';
import '../../../data/enums/req_priority.dart';
import 'requirements_state.dart';
import 'dart:io';
import 'dart:async';

class RequirementsCubit extends Cubit<RequirementsState> {
  /// The repository for requirements operations
  final RequirementsRepository _repository;
  
  /// The page size for pagination
  static const int _pageSize = 10;
  
  /// Timer for debouncing requirements loading
  Timer? _loadRequirementsDebouncer;

  /// Timer for debouncing filter updates
  Timer? _filterDebouncer;

  /// Debounce time for filter updates
  static const Duration _debounceTime = Duration(milliseconds: 300);

  RequirementsCubit(this._repository) : super(const RequirementsState());

  Future<void> loadRequirements(String projectId, {bool refresh = false}) async {
    try {
      if (refresh) {
        emit(state.copyWith(
          status: RequirementsStatus.loading,
          currentPage: 1,
          hasMorePages: true,
          requirements: [],
          selectedRequirementIds: {},
        ));
      } else if (state.status == RequirementsStatus.loading || !state.hasMorePages) {
        return;
      } else {
        emit(state.copyWith(status: RequirementsStatus.loading));
      }
      
      final filter = RequirementsFilter(
        priority: state.filters.priority,
        status: state.filters.status,
        searchQuery: state.filters.searchQuery,
        pageNumber: refresh ? 1 : state.currentPage,
        pageSize: _pageSize,
      );

      final response = await _repository.getProjectRequirements(projectId, filter);
      
      if (response.statusCode == 200) {
        final newRequirements = response.data ?? [];
        final hasMore = newRequirements.length >= _pageSize;
        
        final List<ProjectRequirementsDTO> updatedRequirements = refresh 
            ? newRequirements 
            : [...state.requirements, ...newRequirements];
            
        emit(state.copyWith(
          status: RequirementsStatus.loaded,
          requirements: updatedRequirements,
          currentPage: refresh ? 2 : state.currentPage + 1,
          hasMorePages: hasMore,
          error: null,
          isFilteringInProgress: false,
        ));
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to load requirements',
          isFilteringInProgress: false,
        ));
      }
    } on ValidationException catch (e) {
      developer.log(
        'Validation error loading requirements',
        name: 'RequirementsCubit',
        error: e,
      );
      emit(state.copyWith(
        status: RequirementsStatus.validationError,
        validationErrors: e.errors,
        isFilteringInProgress: false,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Error loading requirements: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
        isFilteringInProgress: false,
      ));
    }
  }

  Future<void> addRequirements(String projectId, List<ReqDTO> requirements) async {
    try {
      emit(state.copyWith(
        status: RequirementsStatus.creating,
        error: null,
        validationErrors: null,
      ));

      final dto = AddReqManuallyDTO(
        projectId: projectId,
        requirements: requirements,
      );

      final response = await _repository.addRequirementsManually(dto);

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: RequirementsStatus.created));
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to add requirements',
        ));
      }
    } on ValidationException catch (e) {
      developer.log(
        'Validation error adding requirements',
        name: 'RequirementsCubit',
        error: e,
      );
      emit(state.copyWith(
        status: RequirementsStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Error adding requirements: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> updateRequirement(String projectId, UpdateRequirementsDTO dto) async {
    try {
      emit(state.copyWith(
        status: RequirementsStatus.updating,
        error: null,
        validationErrors: null,
      ));

      final response = await _repository.updateRequirement(dto);

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: RequirementsStatus.updated));
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to update requirement',
        ));
      }
    } on ValidationException catch (e) {
      developer.log(
        'Validation error updating requirement',
        name: 'RequirementsCubit',
        error: e,
      );
      emit(state.copyWith(
        status: RequirementsStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Error updating requirement: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteRequirements(String projectId, List<String> requirementIds) async {
    try {
      emit(state.copyWith(
        status: RequirementsStatus.deleting,
        error: null,
      ));

      final response = await _repository.deleteRequirements(requirementIds);

      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(
          status: RequirementsStatus.deleted,
          selectedRequirementIds: {},
        ));
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to delete requirements',
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting requirements: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadRequirementsFile(String projectId, String filePath) async {
    try {
      emit(state.copyWith(status: RequirementsStatus.creating));

      final response = await _repository.uploadRequirementsFile(
        projectId,
        file: File(filePath),
      );

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: RequirementsStatus.created));
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to upload requirements file',
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading requirements file: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadWebRequirementsFile(
    String projectId,
    List<int> bytes,
    String fileName,
  ) async {
    try {
      emit(state.copyWith(status: RequirementsStatus.creating));

      final response = await _repository.uploadRequirementsFile(
        projectId,
        webBytes: bytes,
        fileName: fileName,
      );

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: RequirementsStatus.created));
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to upload requirements file',
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading web requirements file: $e',
        name: 'RequirementsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  void updateFilters({
    required String projectId,
    ReqPriority? priority,
    RequirementStatus? status,
    String? searchQuery,
  }) {
    _filterDebouncer?.cancel();

    final newFilters = state.filters.copyWith(
      priority: priority,
      status: status,
      searchQuery: searchQuery,
    );

    // Only proceed if filters actually changed
    if (newFilters == state.filters) return;

    emit(state.copyWith(
      isFilteringInProgress: true,
      filters: newFilters,
    ));

    _filterDebouncer = Timer(_debounceTime, () {
      loadRequirements(projectId, refresh: true);
    });
  }

  void clearFilters() {
    _filterDebouncer?.cancel();
    emit(state.copyWith(
      filters: const FilterState(),
      isFilteringInProgress: false,
      currentPage: 1,
      hasMorePages: true,
      selectedRequirementIds: {},
    ));
  }

  void toggleRequirementSelection(String requirementId) {
    final requirements = state.requirements;
    if (!requirements.any((r) => r.id == requirementId)) {
      final newSelection = Set<String>.from(state.selectedRequirementIds)
        ..remove(requirementId);
      emit(state.copyWith(selectedRequirementIds: newSelection));
      return;
    }

    final newSelection = Set<String>.from(state.selectedRequirementIds);
    if (newSelection.contains(requirementId)) {
      newSelection.remove(requirementId);
    } else {
      newSelection.add(requirementId);
    }
    emit(state.copyWith(selectedRequirementIds: newSelection));
  }

  void clearSelection() {
    emit(state.copyWith(selectedRequirementIds: {}));
  }

  void selectAllRequirements() {
    final allIds = state.requirements.map((r) => r.id).toSet();
    emit(state.copyWith(selectedRequirementIds: allIds));
  }

  @override
  Future<void> close() {
    _loadRequirementsDebouncer?.cancel();
    _filterDebouncer?.cancel();
    return super.close();
  }
} 