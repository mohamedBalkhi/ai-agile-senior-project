class ProjectDTO {
  final String projectName;
  final String? projectDescription;

  ProjectDTO({
    required this.projectName,
    this.projectDescription,
  });

  factory ProjectDTO.fromJson(Map<String, dynamic> json) {
    return ProjectDTO(
      projectName: json['projectName'] as String,
      projectDescription: json['projectDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'projectDescription': projectDescription,
  };
} 