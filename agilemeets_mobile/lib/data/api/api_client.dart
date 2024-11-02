import 'dart:io';

import 'package:agilemeets/models/decoded_token.dart';
import 'package:agilemeets/utils/auth_event_bus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import '../../utils/secure_storage.dart';
import '../models/auth_result.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://192.168.1.101:8080';
  bool _isRefreshing = false;
  bool _isInitialized = false;  // Add this flag
  late PersistCookieJar _cookieJar;

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  Future<void> initialize() async {
    try {
      // Check if already initialized using the flag
      if (_isInitialized) {
        developer.log('ApiClient already initialized', name: 'ApiClient');
        return;
      }

      await _initializeCookieJar();
      
      // Set base URL and default headers
      _dio.options = BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      );

      // Clear any existing interceptors
      _dio.interceptors.clear();

      // Add interceptors in specific order
      _dio.interceptors.addAll([
        CookieManager(_cookieJar),
        
        // Auth interceptor
        InterceptorsWrapper(
          onRequest: _handleRequest,
          onError: _handleError,
        ),

        // Pretty logger - only in debug mode
        if (const bool.fromEnvironment('dart.vm.product') == false)
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            error: true,
            compact: true,
          ),
      ]);

      _isInitialized = true;  // Set initialization flag
      developer.log('ApiClient initialized successfully', name: 'ApiClient');
    } catch (e) {
      developer.log('Error initializing ApiClient: $e', name: 'ApiClient');
      rethrow;
    }
  }

  // Separate request handler for cleaner code
  Future<void> _handleRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // Separate error handler for cleaner code
  Future<void> _handleError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      final wwwAuthenticate = error.response?.headers['www-authenticate']?.first;

      if (wwwAuthenticate?.contains('error="invalid_token"') == true) {
        try {
          final newToken = await refreshToken();
          
          if (newToken != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              developer.log('Retry request failed: $e', name: 'ApiClient');
              return handler.next(error);
            }
          }
          
          // Only logout if refresh fails
          await _handleLogout();
          return handler.reject(error);
          
        } catch (e) {
          developer.log('Token refresh failed: $e', name: 'ApiClient');
          await _handleLogout();
          return handler.reject(error);
        }
      }
    }
    return handler.next(error);
  }

  Future<void> _initializeCookieJar() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    _cookieJar = PersistCookieJar(
      storage: FileStorage('$appDocPath/.cookies/'),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await SecureStorage.deleteAllTokens();
      authEventBus.add(AuthenticationEvent.unauthorized);
    } catch (e) {
      developer.log('Error during logout: $e', name: 'ApiClient');
      rethrow;
    }
  }

  Future<String?> refreshToken() async {
    if (_isRefreshing) return null;
    return _refreshToken();
  }

  Future<String?> _refreshToken() async {
    _isRefreshing = true;
    developer.log('Starting token refresh', name: 'ApiClient');

    try {
      final response = await _dio.post('/api/Auth/refresh');
      
      if (response.data != null) {
        final authResult = AuthResult.fromJson(response.data['data']);
        
        if (authResult.accessToken != null) {
          await SecureStorage.saveToken('access_token', authResult.accessToken!);
          final decodedToken = DecodedToken.fromJwt(authResult.accessToken!);
          await SecureStorage.saveDecodedToken(decodedToken);
          return authResult.accessToken;
        }
      }
      return null;
    } catch (e) {
      developer.log(
        'Error during token refresh request: $e',
        name: 'ApiClient',
        error: e,
      );
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // Update request methods to ensure initialization
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (!_isInitialized) {
      throw Exception('ApiClient not initialized');
    }
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (!_isInitialized) {
      throw Exception('ApiClient not initialized');
    }
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!_isInitialized) {
      throw Exception('ApiClient not initialized');
    }
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
