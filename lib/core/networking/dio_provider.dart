import 'package:dio/dio.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/logging/app_logger.dart';

Dio buildDioClient(
  AppConfig config, {
  required AppLogger logger,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  if (config.enableNetworkLogs) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (Object value) => logger.debug(value.toString()),
      ),
    );
  }

  return dio;
}
