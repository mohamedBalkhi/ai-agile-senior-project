import '../../enums/req_priority.dart';
import '../../enums/requirements_status.dart';

class ProjectRequirementsDTO {
  final String id;
  final String title;
  final String? description;
  final ReqPriority priority;
  final RequirementStatus status;

  const ProjectRequirementsDTO({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
  });

  factory ProjectRequirementsDTO.fromJson(Map<String, dynamic> json) {
    return ProjectRequirementsDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: ReqPriority.fromInt(json['priority'] as int),
      status: RequirementStatus.fromInt(json['status'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.value,
    'status': status.value,
  };
} 