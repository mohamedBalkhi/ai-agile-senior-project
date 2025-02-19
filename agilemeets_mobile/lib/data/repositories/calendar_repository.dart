import 'base_repository.dart';
import '../models/calendar_subscription_dto.dart';
import '../../core/errors/app_exception.dart';

class CalendarRepository extends BaseRepository {
  /// Get all calendar subscriptions
  Future<List<CalendarSubscriptionDTO>> getSubscriptions() async {
    return safeApiCall(
      call: () async {
        final response = await apiClient.get('/api/Calendar/GetSubscriptions');
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data.map((json) => CalendarSubscriptionDTO.fromJson(json)).toList();
      },
      context: 'getSubscriptions',
    );
  }

  /// Create a calendar subscription for personal meetings
  Future<CalendarSubscriptionDTO> createPersonalSubscription() async {
    return safeApiCall(
      call: () async {
        const dto = CreateCalendarSubscriptionDTO(
          feedType: CalendarFeedType.personal,
        );

        final response = await apiClient.post(
          '/api/Calendar/CreateSubscription',
          data: dto.toJson(),
        );

        return CalendarSubscriptionDTO.fromJson(response.data['data']);
      },
      context: 'createPersonalSubscription',
    );
  }

  /// Create a calendar subscription for project meetings
  Future<CalendarSubscriptionDTO> createProjectSubscription(String projectId) async {
    validateParams({'projectId': projectId});
    
    return safeApiCall(
      call: () async {
        final dto = CreateCalendarSubscriptionDTO(
          feedType: CalendarFeedType.project,
          projectId: projectId,
        );

        final response = await apiClient.post(
          '/api/Calendar/CreateSubscription',
          data: dto.toJson(),
        );

        return CalendarSubscriptionDTO.fromJson(response.data['data']);
      },
      context: 'createProjectSubscription',
    );
  }

  /// Create a calendar subscription for a recurring meeting series
  Future<CalendarSubscriptionDTO> createSeriesSubscription(String recurringPatternId) async {
    validateParams({'recurringPatternId': recurringPatternId});
    
    return safeApiCall(
      call: () async {
        final dto = CreateCalendarSubscriptionDTO(
          feedType: CalendarFeedType.series,
          recurringPatternId: recurringPatternId,
        );

        final response = await apiClient.post(
          '/api/Calendar/CreateSubscription',
          data: dto.toJson(),
        );

        return CalendarSubscriptionDTO.fromJson(response.data['data']);
      },
      context: 'createSeriesSubscription',
    );
  }

  /// Revoke a calendar subscription
  Future<bool> revokeSubscription(String token) async {
    validateParams({'token': token});
    
    return safeApiCall(
      call: () async {
        final response = await apiClient.delete('/api/Calendar/RevokeSubscription/$token');
        return response.data['data'] as bool;
      },
      context: 'revokeSubscription',
    );
  }

  /// Get calendar feed URL for all meetings
  Future<String> getPersonalCalendarFeedUrl() async {
    return safeApiCall(
      call: () async {
        const dto =  CreateCalendarSubscriptionDTO(
          feedType: CalendarFeedType.personal,
        );

        final response = await apiClient.post(
          '/api/Calendar/CreateSubscription',
          data: dto.toJson(),
        );

        final subscription = CalendarSubscriptionDTO.fromJson(response.data['data']);
        if (subscription.feedUrl == null) {
          throw const BusinessException(
            'Failed to get calendar feed URL',
            code: 'FEED_URL_MISSING',
          );
        }

        return subscription.feedUrl!;
      },
    );
  }

  /// Get calendar feed URL for project meetings
  Future<String> getProjectCalendarFeedUrl(String projectId) async {
    validateParams({'projectId': projectId});
    
    return safeApiCall(
      call: () async {
        final dto = CreateCalendarSubscriptionDTO(
          feedType: CalendarFeedType.project,
          projectId: projectId,
        );

        final response = await apiClient.post(
          '/api/Calendar/CreateSubscription',
          data: dto.toJson(),
        );

        final subscription = CalendarSubscriptionDTO.fromJson(response.data['data']);
        if (subscription.feedUrl == null) {
          throw const BusinessException(
            'Failed to get calendar feed URL',
            code: 'FEED_URL_MISSING',
          );
        }

        return subscription.feedUrl!;
      },
    );
  }
} 