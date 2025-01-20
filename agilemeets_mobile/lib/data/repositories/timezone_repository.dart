import '../models/timezone_dto.dart';
import 'base_repository.dart';

class TimeZoneRepository extends BaseRepository {
  TimeZoneRepository();

  Future<List<TimeZoneDTO>> getAllTimezones() async {
    final response = await apiClient.get('/api/TimeZone');
    return (response.data as List)
        .map((json) => TimeZoneDTO.fromJson(json))
        .toList();
  }

  Future<List<TimeZoneDTO>> getCommonTimezones() async {
    final response = await apiClient.get('/api/TimeZone/common');
    return (response.data as List)
        .map((json) => TimeZoneDTO.fromJson(json))
        .toList();
  }

  Future<TimeZoneDTO> getTimezone(String id) async {
    final response = await apiClient.get('/api/TimeZone/$id');
    return TimeZoneDTO.fromJson(response.data);
  }
} 