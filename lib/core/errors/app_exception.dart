class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.userMessage,
    this.statusCode,
    this.cause,
  });

  final String code;
  final String message;
  final String userMessage;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    return 'AppException(code: $code, message: $message, statusCode: $statusCode)';
  }
}
