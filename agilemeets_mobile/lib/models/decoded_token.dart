import 'dart:convert';
// import 'package:convert/convert.dart' as convert;

class DecodedToken {
  // Constants for claim keys
  static const String nameIdentifierClaim = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  static const String emailClaim = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';
  static const String nameClaim = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
  static const String isAdminClaim = 'IsAdmin';
  static const String isTrustedClaim = 'IsTrusted';
  static const String isActiveClaim = 'IsActive';
  static const String expClaim = 'exp';
  static const String issuerClaim = 'iss';
  static const String audienceClaim = 'aud';

  final String userId;
  final String email;
  final String fullName;
  final bool isAdmin;
  final bool isTrusted;
  final bool isActive;
  final int exp;
  final String issuer;
  final String audience;

  DecodedToken({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    required this.isTrusted,
    required this.isActive,
    required this.exp,
    required this.issuer,
    required this.audience,
  });

  factory DecodedToken.fromJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    return DecodedToken(
      userId: payload[nameIdentifierClaim] ?? '',
      email: payload[emailClaim] ?? '',
      fullName: payload[nameClaim] ?? '',
      isAdmin: (payload[isAdminClaim]?.toString().toLowerCase() == 'true') ?? false,
      isTrusted: (payload[isTrustedClaim]?.toString().toLowerCase() == 'true') ?? false,
      isActive: (payload[isActiveClaim]?.toString().toLowerCase() == 'true') ?? false,
      exp: payload[expClaim] is int ? payload[expClaim] : 0,
      issuer: payload[issuerClaim] ?? '',
      audience: payload[audienceClaim] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'isAdmin': isAdmin,
      'isTrusted': isTrusted,
      'isActive': isActive,
      'exp': exp,
      'issuer': issuer,
      'audience': audience,
    };
  }

  factory DecodedToken.fromJson(Map<String, dynamic> json) {
    return DecodedToken(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isTrusted: json['isTrusted'] ?? false,
      isActive: json['isActive'] ?? false,
      exp: json['exp'] is int ? json['exp'] : 0,
      issuer: json['issuer'] ?? '',
      audience: json['audience'] ?? '',
    );
  }

  DateTime get expirationDate => 
      DateTime.fromMillisecondsSinceEpoch(exp * 1000);

  bool get isExpired => 
      DateTime.now().isAfter(expirationDate);
}
