import 'package:flutter/foundation.dart';
import 'package:senior_companion/core/logging/app_logger.dart';

class DebugAppLogger implements AppLogger {
  String _line(String level, String message) {
    return '${DateTime.now().toIso8601String()} [$level] $message';
  }

  @override
  void debug(String message) {
    if (kDebugMode) {
      debugPrint(_line('DEBUG', message));
    }
  }

  @override
  void info(String message) {
    debugPrint(_line('INFO', message));
  }

  @override
  void warn(String message) {
    debugPrint(_line('WARN', message));
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer(_line('ERROR', message));
    if (error != null) {
      buffer.write(' | error=$error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    debugPrint(buffer.toString());
  }
}
