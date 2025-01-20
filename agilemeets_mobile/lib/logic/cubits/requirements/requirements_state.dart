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

// Add sentinel value
const USE_NULL = Symbol('USE_NULL');

class RequirementsState extends Equatable {
  final RequirementsStatus status;
  final List<ProjectRequirementsDTO>? requirements;
  final ProjectRequirementsDTO? selectedRequirement;
  final String? error;
  final List<ValidationError>? validationErrors;
  final ReqPriority? priorityFilter;
  final RequirementStatus? statusFilter;
  final String? searchQuery;
  final int currentPage;
  final bool hasMorePages;
  final Set<String> selectedRequirementIds;

  const RequirementsState({
    this.status = RequirementsStatus.initial,
    this.requirements,
    this.selectedRequirement,
    this.error,
    this.validationErrors,
    this.priorityFilter,
    this.statusFilter,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.selectedRequirementIds = const {},
  });

  RequirementsState copyWith({
    RequirementsStatus? status,
    Object? requirements = USE_NULL,
    Object? selectedRequirement = USE_NULL,
    Object? error = USE_NULL,
    Object? validationErrors = USE_NULL,
    Object? priorityFilter = USE_NULL,
    Object? statusFilter = USE_NULL,
    Object? searchQuery = USE_NULL,
    int? currentPage,
    bool? hasMorePages,
    Set<String>? selectedRequirementIds,
  }) {
    return RequirementsState(
      status: status ?? this.status,
      requirements: requirements == USE_NULL ? this.requirements : (requirements as List<ProjectRequirementsDTO>?),
      selectedRequirement: selectedRequirement == USE_NULL ? this.selectedRequirement : (selectedRequirement as ProjectRequirementsDTO?),
      error: error == USE_NULL ? this.error : (error as String?),
      validationErrors: validationErrors == USE_NULL ? this.validationErrors : (validationErrors as List<ValidationError>?),
      priorityFilter: priorityFilter == USE_NULL ? this.priorityFilter : (priorityFilter as ReqPriority?),
      statusFilter: statusFilter == USE_NULL ? this.statusFilter : (statusFilter as RequirementStatus?),
      searchQuery: searchQuery == USE_NULL ? this.searchQuery : (searchQuery as String?),
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      selectedRequirementIds: selectedRequirementIds ?? this.selectedRequirementIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requirements,
    selectedRequirement,
    error,
    validationErrors,
    priorityFilter,
    statusFilter,
    searchQuery,
    currentPage,
    hasMorePages,
    selectedRequirementIds,
  ];
} 