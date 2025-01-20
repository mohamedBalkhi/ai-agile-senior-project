import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../data/repositories/project_repository.dart';
import '../../../data/exceptions/validation_exception.dart';
import 'project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  final ProjectRepository _projectRepository;

  ProjectCubit(this._projectRepository) : super(const ProjectState());

  Future<void> createProject({
    required String projectName,
    String? projectDescription,
    String? projectManagerId,
  }) async {
    try {
      emit(state.copyWith(
        status: ProjectStatus.creating,
        error: null,
        validationErrors: null,
      ));
      
      final response = await _projectRepository.createProject(
        projectName: projectName,
        projectDescription: projectDescription,
        projectManagerId: projectManagerId,
      );

      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(status: ProjectStatus.created));
        // Refresh projects list after creation
        await loadProjects();
      } else {
        emit(state.copyWith(
          status: ProjectStatus.error,
          error: response.message ?? 'Failed to create project',
        ));
      }
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProjectStatus.validationError,
        validationErrors: e.errors,
      ));
    } catch (e) {
      developer.log(
        'Error creating project: $e',
        name: 'ProjectCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProjectStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadProjects() async {
    try {
      emit(state.copyWith(status: ProjectStatus.loading));
      
      final response = await _projectRepository.getProjects();
      
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(
          status: ProjectStatus.loaded,
          projects: response.data,
        ));
      } else {
        emit(state.copyWith(
          status: ProjectStatus.error,
          error: response.message ?? 'Failed to load projects',
        ));
      }
    } catch (e) {
      developer.log(
        'Error loading projects: $e',
        name: 'ProjectCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProjectStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadProjectDetails(String projectId) async {
    try {
      emit(state.copyWith(status: ProjectStatus.loading));
      
      final response = await _projectRepository.getProjectInfo(projectId);
      
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(
          status: ProjectStatus.loaded,
          selectedProject: response.data,
        ));
        
        // Load project members
        await loadProjectMembers(projectId);
        // Load member privileges
        await loadMemberPrivileges(projectId);
      } else {
        emit(state.copyWith(
          status: ProjectStatus.error,
          error: response.message ?? 'Failed to load project details',
        ));
      }
    } catch (e) {
      developer.log(
        'Error loading project details: $e',
        name: 'ProjectCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProjectStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadProjectMembers(String projectId) async {
    try {
      print('Before loading members - selectedProject: ${state.selectedProject?.projectName}');
      developer.log(
        'Before loading members - selectedProject: ${state.selectedProject?.projectName}',
        name: 'ProjectCubit',
      );
      
      final response = await _projectRepository.getProjectMembers(projectId);
      
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(projectMembers: response.data));
      }
      print('After loading members - selectedProject: ${state.selectedProject?.projectName}');
      developer.log(
        'After loading members - selectedProject: ${state.selectedProject?.projectName}',
        name: 'ProjectCubit',
      );
    } catch (e) {
      print(e);
      developer.log(
        'Error loading project members: $e',
        name: 'ProjectCubit',
        error: e,
      );
    }
  }

  Future<void> loadMemberPrivileges(String projectId) async {
    try {
      final response = await _projectRepository.getMemberPrivileges(projectId);
      print('Before setting member privileges - selectedProject: ${state.selectedProject?.projectName}');
      if (response.statusCode == 200 && response.data != null) {
        emit(state.copyWith(memberPrivileges: response.data));
      }
      print('After setting member privileges - selectedProject: ${state.selectedProject?.projectName}');
    } catch (e) {
      developer.log(
        'Error loading member privileges: $e',
        name: 'ProjectCubit',
        error: e,
      );
    }
  }

  Future<void> assignMember({
    required String projectId,
    required String memberId,
    required int meetingsPrivilegeLevel,
    required int membersPrivilegeLevel,
    required int requirementsPrivilegeLevel,
    required int tasksPrivilegeLevel,
    required int settingsPrivilegeLevel,
  }) async {
    try {
      emit(state.copyWith(status: ProjectStatus.updating));
      
      final response = await _projectRepository.assignMember(
        projectId: projectId,
        memberId: memberId,
        meetingsPrivilegeLevel: meetingsPrivilegeLevel,
        membersPrivilegeLevel: membersPrivilegeLevel,
        requirementsPrivilegeLevel: requirementsPrivilegeLevel,
        tasksPrivilegeLevel: tasksPrivilegeLevel,
        settingsPrivilegeLevel: settingsPrivilegeLevel,
      );

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: ProjectStatus.updated));
        // Refresh project members after assignment
        await loadProjectMembers(projectId);
      } else {
        emit(state.copyWith(
          status: ProjectStatus.error,
          error: response.message ?? 'Failed to assign member',
        ));
      }
    } catch (e) {
      developer.log(
        'Error assigning member: $e',
        name: 'ProjectCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProjectStatus.error,
        error: e.toString(),
      ));
    }
  }

  bool canManageMembers() {
    return state.memberPrivileges?.canManageMembers() ?? false;
  }

  bool canManageMeetings() {
    return state.memberPrivileges?.canManageMeetings() ?? false;
  }

  bool canManageRequirements() {
    return state.memberPrivileges?.canManageRequirements() ?? false;
  }

  bool canManageTasks() {
    return state.memberPrivileges?.canManageTasks() ?? false;
  }

  bool canManageSettings() {
    return state.memberPrivileges?.canManageSettings() ?? false;
  }

  bool isProjectManager(String userId) {
    return state.selectedProject?.projectManagerId == userId;
  }

  bool canModifyProject(String userId) {
    return isProjectManager(userId) || canManageSettings();
  }

  Future<void> updateMemberPrivileges({
    required String projectId,
    required String memberId,
    required int meetingsPrivilegeLevel,
    required int membersPrivilegeLevel,
    required int requirementsPrivilegeLevel,
    required int tasksPrivilegeLevel,
    required int settingsPrivilegeLevel,
  }) async {
    try {
      emit(state.copyWith(status: ProjectStatus.updating));
      
      final response = await _projectRepository.updateMemberPrivileges(
        projectId: projectId,
        memberId: memberId,
        meetingsPrivilegeLevel: meetingsPrivilegeLevel,
        membersPrivilegeLevel: membersPrivilegeLevel,
        requirementsPrivilegeLevel: requirementsPrivilegeLevel,
        tasksPrivilegeLevel: tasksPrivilegeLevel,
        settingsPrivilegeLevel: settingsPrivilegeLevel,
      );

      if (response.statusCode == 200 && response.data == true) {
        emit(state.copyWith(status: ProjectStatus.updated));
        // Refresh project members after update
        await loadProjectMembers(projectId);
      } else {
        emit(state.copyWith(
          status: ProjectStatus.error,
          error: response.message ?? 'Failed to update member privileges',
        ));
      }
    } catch (e) {
      developer.log(
        'Error updating member privileges: $e',
        name: 'ProjectCubit',
        error: e,
      );
      emit(state.copyWith(
        status: ProjectStatus.error,
        error: e.toString(),
      ));
    }
  }
} 