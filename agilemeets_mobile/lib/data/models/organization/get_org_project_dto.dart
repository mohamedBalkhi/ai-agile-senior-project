class GetOrgProjectDTO {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String projectManager;

  GetOrgProjectDTO({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.projectManager,
  });

  factory GetOrgProjectDTO.fromJson(Map<String, dynamic> json) {
    return GetOrgProjectDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      projectManager: json['projectManager'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'projectManager': projectManager,
    };
  }
}