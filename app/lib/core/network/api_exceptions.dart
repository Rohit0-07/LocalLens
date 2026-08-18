import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiNetworkException extends ApiException {
  ApiNetworkException(super.message);

  factory ApiNetworkException.fromDio(DioException error) =>
      ApiNetworkException(switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Connection timed out',
        DioExceptionType.connectionError => 'Cannot reach the server',
        _ => 'Unexpected network error',
      });
}

class ApiServerException extends ApiException {
  ApiServerException({
    required this.statusCode,
    required this.code,
    required String message,
  }) : super(message);

  final int statusCode;
  final String code;

  factory ApiServerException.fromDio(DioException error) {
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? '${data['detail'] ?? error.message}'
        : (error.message ?? 'Unknown error');
    final code = data is Map<String, dynamic>
        ? '${data['code'] ?? 'unknown'}'
        : 'unknown';
    return ApiServerException(
      statusCode: error.response?.statusCode ?? 0,
      code: code,
      message: message,
    );
  }
}

class ApiUnauthorizedException extends ApiServerException {
  ApiUnauthorizedException({
    required super.statusCode,
    required super.code,
    required super.message,
  });
}

/// The server responded successfully, but the body was not a list of
/// parseable `Issue` objects (e.g. an error envelope behind a 200 proxy, a
/// non-list body, or a malformed item).
class ApiParseException extends ApiException {
  ApiParseException(super.message);
}

ApiException mapDioException(DioException error) {
  if (error.type == DioExceptionType.badResponse) {
    if (error.response?.statusCode == 401) {
      return ApiUnauthorizedException(
        statusCode: 401,
        code: 'unauthorized',
        message: 'Session expired',
      );
    }
    return ApiServerException.fromDio(error);
  }
  return ApiNetworkException.fromDio(error);
}
