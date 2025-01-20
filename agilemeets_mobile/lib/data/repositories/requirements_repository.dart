import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/requirements/add_req_manually_dto.dart';
import '../models/requirements/project_requirements_dto.dart';
import '../models/requirements/update_requirements_dto.dart';
import '../models/requirements/requirements_filter.dart';
import 'base_repository.dart';

class RequirementsRepository extends BaseRepository {
  RequirementsRepository() : super();

  Future<ApiResponse<List<ProjectRequirementsDTO>>> getProjectRequirements(
    String projectId,
    RequirementsFilter filter,
  ) async {
    final response = await apiClient.get(
      '/api/Requirements/GetProjectRequirements',
      queryParameters: {
        'projectId': projectId,
        ...filter.toQueryParameters(),
      },
    );

    return ApiResponse<List<ProjectRequirementsDTO>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((e) => ProjectRequirementsDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<bool>> addRequirementsManually(AddReqManuallyDTO dto) async {
    final response = await apiClient.post(
      '/api/Requirements/AddReqManually',
      data: dto.toJson(),
    );

    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }

  Future<ApiResponse<bool>> updateRequirement(UpdateRequirementsDTO dto) async {
    final response = await apiClient.put(
      '/api/Requirements/UpdateReq',
      data: dto.toJson(),
    );

    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }

  Future<ApiResponse<List<bool>>> deleteRequirements(List<String> requirementIds) async {
    final response = await apiClient.delete(
      '/api/Requirements/DeleteReqs',
      data: requirementIds,
    );

    return ApiResponse<List<bool>>.fromJson(
      response.data,
      (json) => (json as List).map((e) => e as bool).toList(),
    );
  }

  Future<ApiResponse<bool>> uploadRequirementsFile(
    String projectId, {
    File? file,
    List<int>? webBytes,
    String? fileName,
  }) async {
    final formData = FormData.fromMap({
      if (file != null)
        'file': await MultipartFile.fromFile(file.path)
      else if (webBytes != null && fileName != null)
        'file': MultipartFile.fromBytes(
          webBytes,
          filename: fileName,
        ),
    });

    final response = await apiClient.post(
      '/api/Requirements/UploadRequirementsFile',
      data: formData,
      queryParameters: {'projectId': projectId},
    );

    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }
} 