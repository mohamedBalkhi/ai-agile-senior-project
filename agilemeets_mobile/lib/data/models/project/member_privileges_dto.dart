import '../../enums/privilege_level.dart';

class MemberPrivilegesDTO {
  final PrivilegeLevel meetingsPrivilegeLevel;
  final PrivilegeLevel membersPrivilegeLevel;
  final PrivilegeLevel requirementsPrivilegeLevel;
  final PrivilegeLevel tasksPrivilegeLevel;
  final PrivilegeLevel settingsPrivilegeLevel;

  const MemberPrivilegesDTO({
    required this.meetingsPrivilegeLevel,
    required this.membersPrivilegeLevel,
    required this.requirementsPrivilegeLevel,
    required this.tasksPrivilegeLevel,
    required this.settingsPrivilegeLevel,
  });

  factory MemberPrivilegesDTO.fromJson(Map<String, dynamic> json) {
    return MemberPrivilegesDTO(
      meetingsPrivilegeLevel: PrivilegeLevel.fromString(json['meetingsPrivilegeLevel']),
      membersPrivilegeLevel: PrivilegeLevel.fromString(json['membersPrivilegeLevel']),
      requirementsPrivilegeLevel: PrivilegeLevel.fromString(json['requirementsPrivilegeLevel']),
      tasksPrivilegeLevel: PrivilegeLevel.fromString(json['tasksPrivilegeLevel']),
      settingsPrivilegeLevel: PrivilegeLevel.fromString(json['settingsPrivilegeLevel']),
    );
  }

  Map<String, dynamic> toJson() => {
    'meetingsPrivilegeLevel': meetingsPrivilegeLevel.value,
    'membersPrivilegeLevel': membersPrivilegeLevel.value,
    'requirementsPrivilegeLevel': requirementsPrivilegeLevel.value,
    'tasksPrivilegeLevel': tasksPrivilegeLevel.value,
    'settingsPrivilegeLevel': settingsPrivilegeLevel.value,
  };

  bool canManageMeetings() => meetingsPrivilegeLevel.canWrite;
  bool canViewMeetings() => meetingsPrivilegeLevel.canRead;
  
  bool canManageMembers() => membersPrivilegeLevel.canWrite;
  bool canViewMembers() => membersPrivilegeLevel.canRead;
  
  bool canManageRequirements() => requirementsPrivilegeLevel.canWrite;
  bool canViewRequirements() => requirementsPrivilegeLevel.canRead;
  
  bool canManageTasks() => tasksPrivilegeLevel.canWrite;
  bool canViewTasks() => tasksPrivilegeLevel.canRead;
  
  bool canManageSettings() => settingsPrivilegeLevel.canWrite;
  bool canViewSettings() => settingsPrivilegeLevel.canRead;
} 