import 'package:dio/dio.dart';
import 'package:senior_companion/core/errors/error_mapper.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/shared/models/app_result.dart';

class ApiClient {
  const ApiClient({
    required this.dio,
    required this.logger,
  });

  final Dio dio;
  final AppLogger logger;

  Future<AppResult<T>> guard<T>(Future<T> Function() request) async {
    try {
      final data = await request();
      return AppResult.success(data);
    } on DioException catch (error, stack) {
      final mapped = AppErrorMapper.fromDioException(error);
      logger.warn('Network error: ${mapped.message}');
      logger.error('Dio exception captured by ApiClient', error, stack);
      return AppResult.failure(AppErrorMapper.toApiError(mapped));
    } catch (error, stack) {
      logger.error('Unexpected exception captured by ApiClient', error, stack);
      return AppResult.failure(AppErrorMapper.toApiError(error));
    }
  }
}
