import '../../enums/req_priority.dart';
import '../../enums/requirements_status.dart';

class ReqDTO {
  final String title;
  final String? description;
  final ReqPriority priority;
  final RequirementStatus status;

  const ReqDTO({
    required this.title,
    this.description,
    required this.priority,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'priority': priority.value,
    'status': status.value,
  };

  factory ReqDTO.fromJson(Map<String, dynamic> json) {
    return ReqDTO(
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: ReqPriority.fromInt(json['priority'] as int),
      status: RequirementStatus.fromInt(json['status'] as int),
    );
  }
} 