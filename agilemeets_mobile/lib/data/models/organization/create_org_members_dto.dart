class CreateOrgMembersDTO {
  final List<String>? emails;

  CreateOrgMembersDTO({
    this.emails,
  });

  factory CreateOrgMembersDTO.fromJson(Map<String, dynamic> json) {
    return CreateOrgMembersDTO(
      emails: (json['emails'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emails': emails,
    };
  }
} 