import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/models/organization/get_org_project_dto.dart';

class HomePageDTO {
  final List<GetOrgProjectDTO> activeProjects;
  final List<MeetingDTO> upcomingMeetings;
  final int totalProjectCount;
  final int totalUpcomingMeetingsCount;

  HomePageDTO({
    required this.activeProjects,
    required this.upcomingMeetings,
    required this.totalProjectCount,
    required this.totalUpcomingMeetingsCount,
  });

  factory HomePageDTO.fromJson(Map<String, dynamic> json) {
    return HomePageDTO(
      activeProjects: (json['activeProjects'] as List<dynamic>)
          .map((e) => GetOrgProjectDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingMeetings: (json['upcomingMeetings'] as List<dynamic>)
          .map((e) => MeetingDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalProjectCount: json['totalProjectCount'] as int,
      totalUpcomingMeetingsCount: json['totalUpcomingMeetingsCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeProjects': activeProjects.map((e) => e.toJson()).toList(),
        'upcomingMeetings': upcomingMeetings.map((e) => e.toJson()).toList(),
        'totalProjectCount': totalProjectCount,
        'totalUpcomingMeetingsCount': totalUpcomingMeetingsCount,
      };
} 