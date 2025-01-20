class UpdateProfileDTO {
  final String? fullName;
  final DateTime? birthDate;
  final String? countryId;

  UpdateProfileDTO({
    this.fullName,
    this.birthDate,
    this.countryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String().split('T')[0],
      'countryId': countryId,
    };
  }
} 