import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/project/project_info_dto.dart';
import '../../../data/models/project/project_member_dto.dart';
import '../../../data/models/project/member_privileges_dto.dart';

enum ProjectStatus {
  initial,
  loading,
  loaded,
  error,
  validationError,
  creating,
  created,
  updating,
  updated,
}

class ProjectState extends Equatable {
  final ProjectStatus status;
  final List<ProjectInfoDTO>? projects;
  final ProjectInfoDTO? selectedProject;
  final List<ProjectMemberDTO>? projectMembers;
  final MemberPrivilegesDTO? memberPrivileges;
  final String? error;
  final List<ValidationError>? validationErrors;

  const ProjectState({
    this.status = ProjectStatus.initial,
    this.projects,
    this.selectedProject,
    this.projectMembers,
    this.memberPrivileges,
    this.error,
    this.validationErrors,
  });

  ProjectState copyWith({
    ProjectStatus? status,
    List<ProjectInfoDTO>? projects,
    ProjectInfoDTO? selectedProject,
    List<ProjectMemberDTO>? projectMembers,
    MemberPrivilegesDTO? memberPrivileges,
    String? error,
    List<ValidationError>? validationErrors,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      projectMembers: projectMembers ?? this.projectMembers,
      memberPrivileges: memberPrivileges ?? this.memberPrivileges,
      error: error ?? this.error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
        status,
        projects,
        selectedProject,
        projectMembers,
        memberPrivileges,
        error,
        validationErrors,
      ];
} 