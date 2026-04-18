import 'package:dio/dio.dart';
import 'package:senior_companion/core/errors/app_exception.dart';
import 'package:senior_companion/shared/models/api_error.dart';

class AppErrorMapper {
  static AppException fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return AppException(
        code: 'network-timeout',
        message: exception.message ?? 'Network timeout',
        userMessage: 'Connection issue. Please try again.',
        statusCode: statusCode,
        cause: exception,
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return AppException(
        code: 'auth-error',
        message: exception.message ?? 'Unauthorized request',
        userMessage: 'Your session may have expired.',
        statusCode: statusCode,
        cause: exception,
      );
    }

    return AppException(
      code: 'api-error',
      message: exception.message ?? 'Unknown API error',
      userMessage: 'Something went wrong. Please try again later.',
      statusCode: statusCode,
      cause: exception,
    );
  }

  static ApiError toApiError(Object error) {
    if (error is AppException) {
      return ApiError(
        code: error.code,
        message: error.message,
        userMessage: error.userMessage,
        statusCode: error.statusCode,
      );
    }

    return ApiError(
      code: 'unknown',
      message: error.toString(),
      userMessage: 'Unexpected error. Please try again.',
    );
  }
}
