import '../../enums/req_priority.dart';
import '../../enums/requirements_status.dart';

class RequirementsFilter {
  final ReqPriority? priority;
  final RequirementStatus? status;
  final String? searchQuery;
  final int pageNumber;
  final int pageSize;

  const RequirementsFilter({
    this.priority,
    this.status,
    this.searchQuery,
    required this.pageNumber,
    required this.pageSize,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    if (priority != null) {
      params['Priority'] = priority!.value;
    }
    if (status != null) {
      params['Status'] = status!.value;
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['SearchQuery'] = searchQuery;
    }

    return params;
  }

  RequirementsFilter copyWith({
    ReqPriority? priority,
    RequirementStatus? status,
    String? searchQuery,
    int? pageNumber,
    int? pageSize,
  }) {
    return RequirementsFilter(
      priority: priority ?? this.priority,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }
} 