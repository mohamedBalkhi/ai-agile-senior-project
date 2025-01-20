import '../../enums/req_priority.dart';
import '../../enums/requirements_status.dart';

class UpdateRequirementsDTO {
  final String requirementId;
  final String title;
  final String? description;
  final RequirementStatus status;
  final ReqPriority priority;

  const UpdateRequirementsDTO({
    required this.requirementId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'requirementId': requirementId,
    'title': title,
    'description': description,
    'status': status.value,
    'priority': priority.value,
  };
} 