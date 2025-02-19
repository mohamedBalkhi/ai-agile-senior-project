import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:agilemeets/data/enums/requirements_status.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/requirements/project_requirements_dto.dart';
import '../../../data/enums/req_priority.dart';

enum RequirementsStatus {
  initial,
  loading,
  loaded,
  error,
  validationError,
  creating,
  created,
  updating,
  updated,
  deleting,
  deleted,
}

class FilterState extends Equatable {
  final ReqPriority? priority;
  final RequirementStatus? status;
  final String searchQuery;

  const FilterState({
    this.priority,
    this.status,
    this.searchQuery = '',
  });

  bool get hasActiveFilters => 
    priority != null || status != null || searchQuery.isNotEmpty;

  FilterState copyWith({
    ReqPriority? priority,
    RequirementStatus? status,
    String? searchQuery,
  }) {
    return FilterState(
      priority: priority,
      status: status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (priority != null) params['Priority'] = priority!.value;
    if (status != null) params['Status'] = status!.value;
    if (searchQuery.isNotEmpty) params['SearchQuery'] = searchQuery;
    return params;
  }

  @override
  List<Object?> get props => [priority, status, searchQuery];
}

class RequirementsState extends Equatable {
  final RequirementsStatus status;
  final List<ProjectRequirementsDTO> requirements;
  final FilterState filters;
  final String? error;
  final List<ValidationError>? validationErrors;
  final int currentPage;
  final bool hasMorePages;
  final Set<String> selectedRequirementIds;
  final bool isFilteringInProgress;

  const RequirementsState({
    this.status = RequirementsStatus.initial,
    this.requirements = const [],
    this.filters = const FilterState(),
    this.error,
    this.validationErrors,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.selectedRequirementIds = const {},
    this.isFilteringInProgress = false,
  });

  RequirementsState copyWith({
    RequirementsStatus? status,
    List<ProjectRequirementsDTO>? requirements,
    FilterState? filters,
    String? error,
    List<ValidationError>? validationErrors,
    int? currentPage,
    bool? hasMorePages,
    Set<String>? selectedRequirementIds,
    bool? isFilteringInProgress,
  }) {
    return RequirementsState(
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      filters: filters ?? this.filters,
      error: error,
      validationErrors: validationErrors,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      selectedRequirementIds: selectedRequirementIds ?? this.selectedRequirementIds,
      isFilteringInProgress: isFilteringInProgress ?? this.isFilteringInProgress,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requirements,
    filters,
    error,
    validationErrors,
    currentPage,
    hasMorePages,
    selectedRequirementIds,
    isFilteringInProgress,
  ];

  @override
  String toString() => 'RequirementsState('
    'status: $status, '
    'requirements: ${requirements.length}, '
    'error: $error, '
    'filters: {priority: ${filters.priority}, status: ${filters.status}, search: ${filters.searchQuery}}, '
    'page: $currentPage, '
    'hasMore: $hasMorePages, '
    'selected: ${selectedRequirementIds.length}'
    ')';
} 