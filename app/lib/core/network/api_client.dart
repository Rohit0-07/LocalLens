import 'package:dio/dio.dart';

import 'api_exceptions.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required String? Function() accessTokenProvider,
    void Function()? onUnauthorized,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
           headers: {'Accept': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(_AuthInterceptor(accessTokenProvider, onUnauthorized));
  }

  final Dio _dio;

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return response.data;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    bool expectNoContent = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(
          responseType: expectNoContent
              ? ResponseType.plain
              : ResponseType.json,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<dynamic> patchJson(
    String path, {
    Object? body,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: body,
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: body,
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._accessTokenProvider, this._onUnauthorized);

  final String? Function() _accessTokenProvider;
  final void Function()? _onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessTokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
