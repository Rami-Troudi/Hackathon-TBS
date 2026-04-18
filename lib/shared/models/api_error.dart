class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    required this.userMessage,
    this.statusCode,
  });

  final String code;
  final String message;
  final String userMessage;
  final int? statusCode;
}
