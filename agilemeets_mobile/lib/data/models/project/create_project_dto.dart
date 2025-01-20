class CreateProjectDTO {
  final String projectName;
  final String? projectDescription;
  final String? projectManagerId;

  CreateProjectDTO({
    required this.projectName,
    this.projectDescription,
    this.projectManagerId,
  });

  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'projectDescription': projectDescription,
    'projectManagerId': projectManagerId,
  };
} 