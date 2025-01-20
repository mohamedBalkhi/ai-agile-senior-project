class ProjectInfoDTO {
  final String projectId;
  final String projectName;
  final String? projectDescription;
  final bool projectStatus;
  final String projectManagerId;
  final String? projectManagerName;
  final DateTime? projectCreatedAt;

  ProjectInfoDTO({
    required this.projectId,
    required this.projectName,
    this.projectDescription,
    required this.projectStatus,
    required this.projectManagerId,
    this.projectManagerName,
    this.projectCreatedAt,
  });

  factory ProjectInfoDTO.fromJson(Map<String, dynamic> json) {
    return ProjectInfoDTO(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      projectDescription: json['projectDescription'] as String?,
      projectStatus: json['projectStatus'] as bool,
      projectManagerId: json['projectManagerId'] as String,
      projectManagerName: json['projectManagerName'] as String?,
      projectCreatedAt: json['projectCreatedAt'] != null
          ? DateTime.parse(json['projectCreatedAt'])
          : null,
    );
  }
} 