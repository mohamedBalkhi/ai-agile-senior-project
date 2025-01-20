import 'dart:developer';

import '../models/country_dto.dart';
import '../models/api_response.dart';
import 'base_repository.dart';
class CountryRepository extends BaseRepository {
  Future<List<CountryDTO>> getAllCountries() async {
    try {
      final response = await apiClient.get('/api/Country/GetAllCountries');
      final apiResponse = ApiResponse<List<CountryDTO>>.fromJson(
        response.data,
        (data) => (data as List).map((json) => CountryDTO.fromJson(json)).toList(),
      );
      if (apiResponse.statusCode == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message ?? 'Failed to fetch countries');
      }
    } catch (e) {
      log('Error fetching countries: $e', name: 'CountryRepository');
      return []; // Return an empty list if there's an error
    }
  }
}
