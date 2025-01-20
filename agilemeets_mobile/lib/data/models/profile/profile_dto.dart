class ProfileDTO {
  final String? fullName;
  final String? email;
  final String? countryName;
  final DateTime? birthDate;
  final String? organizationName;

  ProfileDTO({
    this.fullName,
    this.email,
    this.countryName,
    this.birthDate,
    this.organizationName,
  });

  factory ProfileDTO.fromJson(Map<String, dynamic> json) {
    return ProfileDTO(
      fullName: json['fullName'],
      email: json['email'],
      countryName: json['countryName'],
      birthDate: json['birthDate'] != null 
        ? DateTime.parse(json['birthDate']) 
        : null,
      organizationName: json['organizationName'],
    );
  }
} 