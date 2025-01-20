import 'package:agilemeets/data/models/profile/update_profile_dto.dart';

class CompleteProfileDTO {
  final String? fullName;
  final DateTime? birthDate;
  final String countryId;
  final String? password;

  CompleteProfileDTO({
    this.fullName,
    required this.birthDate,
    required this.countryId,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String().split('T')[0], // Only send the date portion
      'countryId': countryId,
      'password': password,
    };
  }

  UpdateProfileDTO toUpdateProfileDTO() {
    return UpdateProfileDTO(
      fullName: fullName,
      birthDate: birthDate,
      countryId: countryId,
    );
  }
} 