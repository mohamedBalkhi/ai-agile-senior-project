class CreateOrganizationDTO {
  final String userId;
  final String name;
  final String description;
  final String? logo;

  CreateOrganizationDTO({
    required this.userId,
    required this.name,
    required this.description,
    this.logo,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      if (logo != null) 'logo': logo,
    };
  }
} 