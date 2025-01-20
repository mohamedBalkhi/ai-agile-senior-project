import 'package:agilemeets/data/models/organization/get_org_member_dto.dart';
import 'package:agilemeets/data/models/organization/get_org_project_dto.dart';
import 'package:agilemeets/data/models/organization/add_members_response_dto.dart';
import 'package:equatable/equatable.dart';

enum OrganizationStatus { initial, loading, success, error }

class OrganizationState extends Equatable {
  final OrganizationStatus status;
  final String? error;
  final String? message;
  final String? organizationId;
  final List<GetOrgMemberDTO> members;
  final String? organizationName;
  final String? organizationDescription;
  final String? organizationLogo;
  final List<GetOrgProjectDTO> projects;
  final AddMembersResponseDTO? lastAddMembersResult;

  const OrganizationState({
    this.status = OrganizationStatus.initial,
    this.error,
    this.message,
    this.organizationId,
    this.members = const [],
    this.organizationName,
    this.organizationDescription,
    this.organizationLogo,
    this.projects = const [],
    this.lastAddMembersResult,
  });

  factory OrganizationState.initial() => const OrganizationState();

  OrganizationState copyWith({
    OrganizationStatus? status,
    String? error,
    String? message,
    String? organizationId,
    List<GetOrgMemberDTO>? members,
    String? organizationName,
    String? organizationDescription,
    String? organizationLogo,
    List<GetOrgProjectDTO>? projects,
    AddMembersResponseDTO? lastAddMembersResult,
  }) {
    return OrganizationState(
      status: status ?? this.status,
      error: error,
      message: message,
      organizationId: organizationId ?? this.organizationId,
      members: members ?? this.members,
      organizationName: organizationName ?? this.organizationName,
      organizationDescription: organizationDescription ?? this.organizationDescription,
      organizationLogo: organizationLogo ?? this.organizationLogo,
      projects: projects ?? this.projects,
      lastAddMembersResult: lastAddMembersResult ?? this.lastAddMembersResult,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        message,
        organizationId,
        members,
        organizationName,
        organizationDescription,
        organizationLogo,
        projects,
        lastAddMembersResult,
      ];
}
