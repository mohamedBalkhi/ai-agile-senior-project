import 'package:agilemeets/data/models/project/project_dto.dart';

class GetOrgMemberDTO {
  final String memberId;
  final String memberName;
  final String memberEmail;
  final bool isActive;
  final bool isAdmin;
  final bool isManager;
  final List<ProjectDTO> projects;

  GetOrgMemberDTO({
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.isActive,
    required this.isAdmin,
    required this.isManager,
    required this.projects,
  });

  factory GetOrgMemberDTO.fromJson(Map<String, dynamic> json) {
    return GetOrgMemberDTO(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      memberEmail: json['memberEmail'] as String,
      isActive: json['isActive'] as bool,
      isAdmin: json['isAdmin'] as bool,
      isManager: json['isManager'] as bool,
      projects: (json['projects'] as List<dynamic>)
          .map((e) => ProjectDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
} 