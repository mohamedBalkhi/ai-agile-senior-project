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

  RequirementsCubit(this._repository) : super(const RequirementsState());

  Future<void> loadRequirements(String projectId, {bool refresh = false}) async {
    try {
      if (refresh) {
        emit(state.copyWith(
          status: RequirementsStatus.loading,
          currentPage: 1,
          hasMorePages: true,
          requirements: null,
          selectedRequirementIds: {},
        ));
      } else if (state.status == RequirementsStatus.loading || !state.hasMorePages) {
        return;
      } else {
        emit(state.copyWith(status: RequirementsStatus.loading));
      }
      print('state.priorityFilter: ${state.priorityFilter}');
      print('state.statusFilter: ${state.statusFilter}');
      print('state.searchQuery: ${state.searchQuery}');
      print('state.currentPage: ${state.currentPage}');
      final filter = RequirementsFilter(
        priority: state.priorityFilter,
        status: state.statusFilter,
        searchQuery: state.searchQuery,
        pageNumber: refresh ? 1 : state.currentPage,
        pageSize: _pageSize,
      );

      final response = await _repository.getProjectRequirements(projectId, filter);
      print('response.statusCode: ${response.statusCode}');
      print('response.data: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        print('response.data: in if ${response.data}');
        final newRequirements = response.data!;
        final hasMore = newRequirements.length >= _pageSize;
        final newTotalRequirements = state.requirements == null ? newRequirements : [...(state.requirements ?? []), ...newRequirements];
        print('newTotalRequirements: $newTotalRequirements');
        emit(state.copyWith(
          status: RequirementsStatus.loaded,
          requirements: refresh 
              ? newRequirements 
              : newTotalRequirements,
          currentPage: refresh ? 2 : state.currentPage + 1,
          hasMorePages: hasMore,
        ));
        print('state.requirements: ${state.requirements}');
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to load requirements',
        ));
      }
    } catch (e) {
      developer.log(
        'Error loading requirements: $e',
        name: 'RequirementsCubit',
        error: e,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
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
      emit(state.copyWith(
        status: RequirementsStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error adding requirements: $e',
        name: 'RequirementsCubit',
        error: e,
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
        // Refresh the requirements list
        await loadRequirements(projectId, refresh: true);
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to update requirement',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: RequirementsStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error updating requirement: $e',
        name: 'RequirementsCubit',
        error: e,
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
        // First emit deleted status with cleared selection
        emit(state.copyWith(
          status: RequirementsStatus.deleted,
          selectedRequirementIds: {},
        ));
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to delete requirements',
        ));
      }
    } catch (e) {
      developer.log(
        'Error deleting requirements: $e',
        name: 'RequirementsCubit',
        error: e,
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
        // Don't load requirements here - let the UI handle it
      } else {
        emit(state.copyWith(
          status: RequirementsStatus.error,
          error: response.message ?? 'Failed to upload requirements file',
        ));
      }
    } catch (e) {
      developer.log(
        'Error uploading requirements file: $e',
        name: 'RequirementsCubit',
        error: e,
      );
      emit(state.copyWith(
        status: RequirementsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadWebRequirementsFile(String projectId, List<int> bytes, String fileName) async {
    await _uploadFile(projectId, webBytes: bytes, fileName: fileName);
  }

  Future<void> _uploadFile(
    String projectId, {
    File? file,
    List<int>? webBytes,
    String? fileName,
  }) async {
    try {
      emit(state.copyWith(
        status: RequirementsStatus.creating,
        error: null,
      ));

      final response = await _repository.uploadRequirementsFile(
        projectId,
        file: file,
        webBytes: webBytes,
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
    } catch (e) {
      developer.log(
        'Error uploading requirements file: $e',
        name: 'RequirementsCubit',
        error: e,
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
    // Keep existing filters unless explicitly changed
    final newPriority = priority != null ? 
        (priority == state.priorityFilter ? null : priority) : 
        state.priorityFilter;
        
    final newStatus = status != null ? 
        (status == state.statusFilter ? null : status) : 
        state.statusFilter;
        
    final newSearchQuery = searchQuery ?? state.searchQuery;

    // Only emit if there are actual changes
    if (newPriority != state.priorityFilter || 
        newStatus != state.statusFilter || 
        newSearchQuery != state.searchQuery) {
      
      emit(state.copyWith(
        priorityFilter: newPriority,
        statusFilter: newStatus,
        searchQuery: newSearchQuery,
        currentPage: 1,
        // Don't reset requirements immediately
        // requirements: null, // Remove this
      ));

      // Debounce the API call
      _loadRequirementsDebouncer?.cancel();
      _loadRequirementsDebouncer = Timer(const Duration(milliseconds: 300), () {
        loadRequirements(
          projectId,
          refresh: true,
        );
      });
    }
  }

  void clearFilters() {
    emit(state.copyWith(
      priorityFilter: null,
      statusFilter: null,
      searchQuery: null,
      currentPage: 1,
      hasMorePages: true,
      selectedRequirementIds: {},
    ));
  }

  void toggleRequirementSelection(String requirementId) {
    final requirements = state.requirements;
    if (requirements == null || !requirements.any((r) => r.id == requirementId)) {
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
    if (state.requirements == null) return;
    final allIds = state.requirements!.map((r) => r.id).toSet();
    emit(state.copyWith(selectedRequirementIds: allIds));
  }

  @override
  Future<void> close() {
    _loadRequirementsDebouncer?.cancel();
    return super.close();
  }
} 