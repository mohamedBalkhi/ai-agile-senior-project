import '../models/api_response.dart';
import '../models/notification_token_dto.dart';
import 'base_repository.dart';

class NotificationsRepository extends BaseRepository {
  Future<ApiResponse<bool>> subscribe(NotificationTokenDTO dto) async {
    final response = await apiClient.post(
      '/api/Notifications/Subscribe',
      data: dto.toJson(),
    );

    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }

  Future<ApiResponse<bool>> unsubscribe(NotificationTokenDTO dto) async {
    final response = await apiClient.post(
      '/api/Notifications/Unsubscribe',
      data: dto.toJson(),
    );

    return ApiResponse<bool>.fromJson(
      response.data,
      (json) => json as bool,
    );
  }
} 