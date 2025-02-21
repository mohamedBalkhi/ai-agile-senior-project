import 'dart:async';
import 'dart:io';
import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/core/errors/error_handler.dart';
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
  final String _baseUrl = 'https://agilemeets-basemgt.fly.dev';
  // final String _baseUrl = 'http://192.168.0.143:8080';
  String get baseUrl => _baseUrl;
 
  bool _isRefreshing = false;
  bool _isInitialized = false;
  late PersistCookieJar _cookieJar;
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        developer.log('ApiClient already initialized', name: 'ApiClient');
        return;
      }

      await _initializeCookieJar();

      _dio.options = BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: null, // Let our error handler deal with status codes
      );

      _dio.interceptors.clear();

      _dio.interceptors.addAll([
        CookieManager(_cookieJar),
        InterceptorsWrapper(
          onRequest: _handleRequest,
          onError: _handleError,
          onResponse: _handleResponse,
        ),
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

      _isInitialized = true;
      developer.log('ApiClient initialized successfully', name: 'ApiClient');
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing ApiClient: $e',
        name: 'ApiClient',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(
        'Failed to initialize API client',
        code: 'INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  Future<void> _handleRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await SecureStorage.getToken('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e,
        ),
      );
    }
  }

  Future<void> _handleResponse(Response response, ResponseInterceptorHandler handler) async {
    // Log all responses regardless of status code
    developer.log(
      '''Response Status: ${response.statusCode}
      Data: ${response.data}
      Headers: ${response.headers}''',
      name: 'ApiClient',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return handler.next(response);
    }
    
    // Let error handler deal with other status codes
    return handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      ),
    );
  }

  Completer<String?>? _refreshCompleter;

  Future<void> _handleError(DioException error, ErrorInterceptorHandler handler) async {
    try {
      // Handle cancellation first and gracefully
      if (_isCancellation(error)) {
        developer.log('Request cancelled by user', name: 'ApiClient');
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: const ServerException(
              'Upload cancelled by user',
              code: 'UPLOAD_CANCELLED',
            ),
            type: DioExceptionType.cancel,
          ),
        );
      }

      // Log detailed error information
      developer.log(
        '''Error Details:
        Status Code: ${error.response?.statusCode}
        Error Type: ${error.type}
        Error Message: ${error.message}
        Response Data: ${error.response?.data}
        Path: ${error.requestOptions.path}
        Method: ${error.requestOptions.method}''',
        name: 'ApiClient',
        error: error,
      );

      // Don't handle token refresh for network errors or cancellations
      if (_isNetworkError(error) || _isCancellation(error)) {
        developer.log('Network error or cancellation detected, not attempting token refresh', 
          name: 'ApiClient');
        return handler.reject(error);
      }

      // Handle 401 errors only for token-related endpoints
      if (error.response?.statusCode == 401) {
        // Don't refresh token for login/refresh endpoints
        if (!error.requestOptions.path.contains('login') && 
            !error.requestOptions.path.contains('refresh')) {
          developer.log('Handling 401 error', name: 'ApiClient');
          return _handleTokenRefresh(error, handler);
        }
      }

      // Convert to our AppException type
      final appException = ErrorHandler.handleDioException(error);
      developer.log('AppException: $appException', name: 'ApiClient');
      
      return handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          error: appException,
          type: DioExceptionType.unknown,
        ),
      );
    } catch (e, stack) {
      developer.log(
        'Error in error handler: $e\nStack trace: $stack',
        name: 'ApiClient',
        error: e,
      );
      return handler.reject(error);
    }
  }

  Future<void> _handleTokenRefresh(DioException error, ErrorInterceptorHandler handler) async {
    RequestOptions options = error.requestOptions;

    try {
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshCompleter = Completer<String?>();
        
        try {
          final result = await _retryWithBackoff(
            () => refreshToken(),
            maxAttempts: 3,
            shouldRetry: (e) => e is DioException && _isNetworkError(e),
          );
          _refreshCompleter?.complete(result);
        } catch (e) {
          // Don't complete with error for network issues
          if (e is DioException && _isNetworkError(e)) {
            developer.log('Network error during token refresh, not completing with error', name: 'ApiClient');
            _refreshCompleter?.complete(null);
          } else {
            _refreshCompleter?.completeError(e);
          }
          rethrow;
        } finally {
          _isRefreshing = false;
        }
      }

      final token = await _refreshCompleter?.future;
      
      if (token != null) {
        developer.log('Retrying request with new token', name: 'ApiClient');
        options.headers['Authorization'] = 'Bearer $token';
        
        try {
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            // Only logout for actual auth errors, not network issues
            if (e.response?.statusCode == 401 && !_isNetworkError(e)) {
              await _handleLogout();
            }
            return handler.reject(e);
          }
          rethrow;
        }
      }
      
      // Only logout if it's not a network error
      if (!_isNetworkError(error)) {
        await _handleLogout();
      }
      return handler.reject(error);
    } catch (e) {
      developer.log(
        'Error during token refresh or retry: $e',
        name: 'ApiClient',
        error: e,
      );
      
      // Don't logout for network errors
      if (e is DioException && _isNetworkError(e)) {
        return handler.reject(e);
      }
      
      // For other errors, proceed with logout
      await _handleLogout();
      return handler.reject(e is DioException ? e : error);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           error.error is SocketException;
  }

  bool _isCancellation(DioException error) {
    return error.type == DioExceptionType.cancel;
  }

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(dynamic)? shouldRetry,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        // Don't retry cancelled requests
        if (e is DioException && _isCancellation(e)) {
          return Future.value() as T; // Return empty value for cancellations
        }
        
        if (attempts >= maxAttempts || (shouldRetry != null && !shouldRetry(e))) {
          rethrow;
        }
        
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  Future<String?> refreshToken() async {
    developer.log('Starting token refresh', name: 'ApiClient');

    try {
      final response = await _dio.post('/api/Auth/refresh');

      if (response.statusCode == 200 && response.data != null) {
        final authResult = AuthResult.fromJson(response.data['data']);

        if (authResult.accessToken != null) {
          await SecureStorage.saveToken('access_token', authResult.accessToken!);
          final decodedToken = DecodedToken.fromJwt(authResult.accessToken!);
          await SecureStorage.saveDecodedToken(decodedToken);
          developer.log('Token refreshed successfully', name: 'ApiClient');
          return authResult.accessToken;
        }
      }
      
      // Only log this message for actual server responses
      if (response.statusCode != null) {
        developer.log('Token refresh failed - invalid response', name: 'ApiClient');
      }
      
      // Don't logout here - let the calling code decide based on the error type
      return null;
    } catch (e) {
      developer.log(
        'Error during token refresh request: $e',
        name: 'ApiClient',
        error: e,
      );
      
      // Don't logout here - let the calling code decide based on the error type
      rethrow;
    }
  }

  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request,
    {int retryCount = 0}
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      // Handle cancellation immediately without retry
      if (_isCancellation(e)) {
        developer.log('Request cancelled by user, not retrying', name: 'ApiClient');
        throw const ServerException(
          'Upload cancelled by user',
          code: 'UPLOAD_CANCELLED',
        );
      }
      
      // Only retry network errors and server errors
      if (retryCount < maxRetries && _shouldRetry(e)) {
        developer.log(
          'Retrying request (attempt ${retryCount + 1}/$maxRetries)',
          name: 'ApiClient'
        );
        await Future.delayed(retryDelay * (retryCount + 1));
        return _retryRequest(request, retryCount: retryCount + 1);
      }
      
      // If we've exhausted retries or shouldn't retry, rethrow
      rethrow;
    }
  }

  bool _shouldRetry(DioException error) {
    // Never retry cancelled requests or client errors
    if (_isCancellation(error) || 
        (error.response?.statusCode != null && 
         error.response!.statusCode! >= 400 && 
         error.response!.statusCode! < 500)) {
      return false;
    }
    
    // Retry network errors and server errors
    return _isNetworkError(error) ||
           error.response?.statusCode == 500 || 
           error.response?.statusCode == 502 || 
           error.response?.statusCode == 503 || 
           error.response?.statusCode == 504;
  }

  // Update public methods to use retry mechanism
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!_isInitialized) {
      throw const ServerException('ApiClient not initialized', code: 'NOT_INITIALIZED');
    }
    return _retryRequest(() => _dio.get(
      path, 
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    ));
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!_isInitialized) {
      throw const ServerException('ApiClient not initialized', code: 'NOT_INITIALIZED');
    }
    return _retryRequest(() => _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    ));
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!_isInitialized) {
      throw const ServerException('ApiClient not initialized', code: 'NOT_INITIALIZED');
    }
    return _retryRequest(() => _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    ));
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (!_isInitialized) {
      throw const ServerException('ApiClient not initialized', code: 'NOT_INITIALIZED');
    }
    return _retryRequest(() => _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
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
}
