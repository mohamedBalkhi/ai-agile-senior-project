class CreateOrganizationDTO {
  final String userId;
  final String name;
  final String? description;
  final String? logo = "some logo";

  CreateOrganizationDTO({
    required this.userId,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'logo': logo,
    };
  }
}
