import '../models/organization/create_org_members_dto.dart';
import '../models/create_organization_dto.dart';
import '../models/api_response.dart';
import 'base_repository.dart';
import '../models/organization/get_org_member_dto.dart';
import '../models/organization/get_org_project_dto.dart';
import '../models/organization/add_members_response_dto.dart';

class OrganizationRepository extends BaseRepository {

  OrganizationRepository() : super();

  Future<String> createOrganization(CreateOrganizationDTO dto) async {
    final response = await apiClient.post(
      '/api/Organization/CreateOrganization',
      data: dto.toJson(),
    );
    final guidResponse = ApiResponse<String>.fromJson(
      response.data,
      (data) => data as String,
    );
    return guidResponse.data ?? '';
  }

  Future<bool> addOrgMembers(CreateOrgMembersDTO dto) async {
    final response = await apiClient.post(
      '/api/Organization/AddOrgMember',
      data: dto.toJson(),
    );
    final boolResponse = ApiResponse<bool>.fromJson(
      response.data,
      (data) => data as bool,
    );
    return boolResponse.data ?? false;
  }

  Future<bool> setMemberAsAdmin(String userId, bool isAdmin) async {
    final response = await apiClient.post(
      '/api/Organization/SetMemberAsAdmin',
      queryParameters: {'userId': userId, 'isAdmin': isAdmin},
    );
    final boolResponse = ApiResponse<bool>.fromJson(
      response.data,
      (data) => data as bool,
    );
    return boolResponse.data ?? false;
  }

  Future<List<GetOrgMemberDTO>> getOrganizationMembers() async {
    final response = await apiClient.get('/api/Organization/GetOrganizationMembers');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => GetOrgMemberDTO.fromJson(json)).toList();
  }

  Future<bool> deactivateOrganization(String organizationId) async {
    final response = await apiClient.post(
      '/api/Organization/DeactivateOrganization',
      data: {'organizationId': organizationId},
    );
    final boolResponse = ApiResponse<bool>.fromJson(
      response.data,
      (data) => data as bool,
    );
    return boolResponse.data ?? false;
  }

  Future<List<GetOrgProjectDTO>> getOrganizationProjects() async {
    try {
      final response = await apiClient.get('/api/Organization/GetOrganizationProjects');
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((project) => GetOrgProjectDTO.fromJson(project)).toList();
      }
      
      throw Exception(response.data['message'] ?? 'Failed to load projects');
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  Future<AddMembersResponseDTO> addMembers(List<String> emails) async {
    try {
      final response = await apiClient.post(
        '/api/Organization/AddOrgMembers',
        data: {
          'emails': emails,
        },
      );
      
      if (response.statusCode == 200) {
        return AddMembersResponseDTO.fromJson(response.data['data']);
      }
      
      throw Exception(response.data['message'] ?? 'Failed to add members');
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }
}
