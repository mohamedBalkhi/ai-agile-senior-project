import 'package:intl/intl.dart';

class SignUpDTO {
  final String? fullName;
  final String email;
  final String password;
  final DateTime? birthDate;
  final String? countryIdCountry;

  SignUpDTO({
    this.fullName,
    required this.email,
    required this.password,
    this.birthDate,
    this.countryIdCountry,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'birthDate': birthDate?.toIso8601String().split('T')[0],
      'country_IdCountry': countryIdCountry,
    };
  }
}
