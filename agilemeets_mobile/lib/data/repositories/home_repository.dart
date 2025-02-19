import 'package:agilemeets/data/models/home_page_dto.dart';
import 'package:agilemeets/data/repositories/base_repository.dart';
import 'package:agilemeets/data/models/api_response.dart';

class HomeRepository extends BaseRepository {

  HomeRepository() : super();

  Future<ApiResponse<HomePageDTO>> getHomePageData() async {
    return safeApiCall<ApiResponse<HomePageDTO>>(
      call: () async {
        final response = await apiClient.get('/api/Home');
        return ApiResponse.fromJson(
          response.data,
          (json) => HomePageDTO.fromJson(json as Map<String, dynamic>),
        );
      },
      context: 'getHomePageData',
    );
  }
} 