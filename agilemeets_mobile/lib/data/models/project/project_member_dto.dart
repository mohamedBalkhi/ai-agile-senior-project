class ProjectMemberDTO {
  final String userId;
  final String memberId;
  final String name;
  final String email;
  final bool isAdmin;
  final String meetings;
  final String members;
  final String requirements;
  final String tasks;
  final String settings;

  ProjectMemberDTO({
    required this.userId,
    required this.memberId,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.meetings,
    required this.members,
    required this.requirements,
    required this.tasks,
    required this.settings,
  });

  factory ProjectMemberDTO.fromJson(Map<String, dynamic> json) {
    return ProjectMemberDTO(
      userId: json['userId'] ?? '',
      memberId: json['memberId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      meetings: json['meetings'] ?? 'None',
      members: json['members'] ?? 'None',
      requirements: json['requirements'] ?? 'None',
      tasks: json['tasks'] ?? 'None',
      settings: json['settings'] ?? 'None',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'memberId': memberId,
    'name': name,
    'email': email,
    'isAdmin': isAdmin,
    'meetings': meetings,
    'members': members,
    'requirements': requirements,
    'tasks': tasks,
    'settings': settings,
  };
}