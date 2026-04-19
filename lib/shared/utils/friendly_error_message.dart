import 'package:senior_companion/core/errors/app_exception.dart';

String toFriendlyErrorMessage(Object error) {
  if (error is AppException) {
    return error.userMessage;
  }
  return 'Something unexpected happened. Please try again.';
}
