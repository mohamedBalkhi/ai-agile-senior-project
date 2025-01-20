class MeetingMemberDTO {
  final String memberId;
  final String? memberName;
  final bool hasConfirmed;
  final String? orgMemberId;
  final String? email;
  final String? userId;

  const MeetingMemberDTO({
    required this.memberId,
    this.memberName,
    this.hasConfirmed = false,
    this.orgMemberId,
    this.email,
    this.userId,
  });

  factory MeetingMemberDTO.fromJson(Map<String, dynamic> json) {
    return MeetingMemberDTO(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String?,
      hasConfirmed: json['hasConfirmed'] as bool? ?? false,
      orgMemberId: json['orgMemberId'] as String?,
      email: json['email'] as String?,
      userId: json['userId'] as String?,  
    );
  }

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'memberName': memberName,
    'hasConfirmed': hasConfirmed,
    'orgMemberId': orgMemberId,
    'email': email,
    'userId': userId,
  };
} 
