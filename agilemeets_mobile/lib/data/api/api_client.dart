import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://your-api-base-url.com';

  ApiClient() {
    _dio.options.baseUrl = _baseUrl;
    // Add any global configurations here (headers, interceptors, etc.)
  }

  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Add other methods (put, delete, etc.) as needed
}
