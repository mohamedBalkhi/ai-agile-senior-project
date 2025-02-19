import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/organization_repository.dart';
import '../../../data/models/create_organization_dto.dart';
import 'organization_state.dart';

class OrganizationCubit extends Cubit<OrganizationState> {
  final OrganizationRepository _repository;

  OrganizationCubit(this._repository) : super(OrganizationState.initial());

  Future<void> createOrganization(String name, String description, String userId) async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      
      final result = await _repository.createOrganization(CreateOrganizationDTO(
        userId: userId,
        name: name,
        description: description,
      ));

      emit(state.copyWith(
        status: OrganizationStatus.success,
        message: 'Organization created successfully',
        organizationId: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> addMembers(List<String> emails) async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      
      final result = await _repository.addMembers(emails);
      
      final members = await _repository.getOrganizationMembers();
      
      String message;
      if (result.successCount > 0 && result.failureCount > 0) {
        message = '${result.successCount} member(s) invited successfully, ${result.failureCount} failed';
      } else if (result.successCount > 0) {
        message = '${result.successCount} member(s) invited successfully';
      } else {
        message = 'No members were invited';
      }

      emit(state.copyWith(
        status: OrganizationStatus.success,
        members: members,
        message: message,
        lastAddMembersResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> setMemberAsAdmin(String userId, bool isAdmin) async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      
      final result = await _repository.setMemberAsAdmin(userId, isAdmin);
      
      if (result) {
        emit(state.copyWith(
          status: OrganizationStatus.success,
          message: 'Member role updated successfully',
        ));
        await loadMembers();
      }
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMembers() async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      final members = await _repository.getOrganizationMembers();
      emit(state.copyWith(
        status: OrganizationStatus.success,
        members: members,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> deactivateOrganization(String organizationId) async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      final result = await _repository.deactivateOrganization(organizationId);
      if (result) {
        emit(state.copyWith(
          status: OrganizationStatus.success,
          message: 'Organization deactivated successfully',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadOrganization() async {
    try {
      emit(state.copyWith(status: OrganizationStatus.loading));
      
      // Load members
      final members = await _repository.getOrganizationMembers();
      
      // Load projects
      final projects = await _repository.getOrganizationProjects();
      
      emit(state.copyWith(
        status: OrganizationStatus.success,
        members: members,
        projects: projects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> getOrganizationProjects() async {
    try {
      final response = await _repository.getOrganizationProjects();
      emit(state.copyWith(
        projects: response,
        status: OrganizationStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        status: OrganizationStatus.error,
      ));
    }
  }
}
