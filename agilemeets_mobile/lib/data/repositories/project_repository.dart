import 'package:agilemeets/data/models/api_response.dart';
import 'package:agilemeets/data/models/project/project_info_dto.dart';
import 'package:agilemeets/data/models/project/project_member_dto.dart';
import 'package:agilemeets/data/models/project/member_privileges_dto.dart';
import 'package:agilemeets/data/repositories/base_repository.dart';
import 'package:dio/dio.dart';

class ProjectRepository extends BaseRepository {
  ProjectRepository() : super();

  Future<ApiResponse<String>> createProject({
    required String projectName,
    String? projectDescription,
    String? projectManagerId,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/Projects/CreateProject',
        data: {
          'projectName': projectName,
          'projectDescription': projectDescription,
          'projectManagerId': projectManagerId,
        },
      );
      return ApiResponse<String>.fromJson(
        response.data,
        (json) => json as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        throw Exception('Server error: Unable to create project. Please try again later.');
      }
      rethrow;
    }
  }

  Future<ApiResponse<List<ProjectMemberDTO>>> getProjectMembers(String projectId) async {
    final response = await apiClient.get(
      '/api/Projects/GetProjectMembers',
      queryParameters: {'projectId': projectId},
    );
    return ApiResponse<List<ProjectMemberDTO>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((e) => ProjectMemberDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<ProjectInfoDTO>> getProjectInfo(String projectId) async {
    final response = await apiClient.get(
      '/api/Projects/GetProjectInfo',
      queryParameters: {'projectId': projectId},
    );
    return ApiResponse<ProjectInfoDTO>.fromJson(
      response.data,
      (json) => ProjectInfoDTO.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<MemberPrivilegesDTO>> getMemberPrivileges(String projectId) async {
    final response = await apiClient.get(
      '/api/Projects/GetMemberPrivileges',
      queryParameters: {'projectId': projectId},
    );
    return ApiResponse<MemberPrivilegesDTO>.fromJson(
      response.data,
      (json) => MemberPrivilegesDTO.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<ProjectInfoDTO>>> getProjects() async {
    final response = await apiClient.get('/api/Projects/GetProjectsByMember');
    return ApiResponse<List<ProjectInfoDTO>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((e) => ProjectInfoDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<bool>> assignMember({
    required String projectId,
    required String memberId,
    required int meetingsPrivilegeLevel,
    required int membersPrivilegeLevel,
    required int requirementsPrivilegeLevel,
    required int tasksPrivilegeLevel,
    required int settingsPrivilegeLevel,
  }) async {
    final response = await apiClient.post(
      '/api/Projects/AssignMember',
      data: {
        'projectId': projectId,
        'memberId': memberId,
        'meetingsPrivilegeLevel': meetingsPrivilegeLevel,
        'membersPrivilegeLevel': membersPrivilegeLevel,
        'requirementsPrivilegeLevel': requirementsPrivilegeLevel,
        'tasksPrivilegeLevel': tasksPrivilegeLevel,
        'settingsPrivilegeLevel': settingsPrivilegeLevel,
      },
    );
    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }

  Future<ApiResponse<bool>> updateMemberPrivileges({
    required String projectId,
    required String memberId,
    required int meetingsPrivilegeLevel,
    required int membersPrivilegeLevel,
    required int requirementsPrivilegeLevel,
    required int tasksPrivilegeLevel,
    required int settingsPrivilegeLevel,
  }) async {
    final response = await apiClient.put(
      '/api/Projects/UpdateProjectPrivileges',
      data: {
        'projectId': projectId,
        'memberId': memberId,
        'meetingsPrivilegeLevel': meetingsPrivilegeLevel,
        'membersPrivilegeLevel': membersPrivilegeLevel,
        'requirementsPrivilegeLevel': requirementsPrivilegeLevel,
        'tasksPrivilegeLevel': tasksPrivilegeLevel,
        'settingsPrivilegeLevel': settingsPrivilegeLevel,
      },
    );
    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }
} 