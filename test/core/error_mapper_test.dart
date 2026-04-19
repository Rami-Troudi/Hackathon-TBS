import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/errors/app_exception.dart';
import 'package:senior_companion/core/errors/error_mapper.dart';
import 'package:senior_companion/shared/models/api_error.dart';

void main() {
  group('AppErrorMapper', () {
    // ── toApiError — AppException input ───────────────────────────────────────

    group('toApiError with AppException', () {
      test('maps code correctly', () {
        const exception = AppException(
          code: 'checkin-failed',
          message: 'Storage returned false',
          userMessage: 'Could not save your check-in.',
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error.code, equals('checkin-failed'));
      });

      test('maps technical message correctly', () {
        const exception = AppException(
          code: 'storage-error',
          message: 'SharedPreferences.setString returned false',
          userMessage: 'Could not save your settings.',
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error.message,
            equals('SharedPreferences.setString returned false'));
      });

      test('maps userMessage correctly', () {
        const exception = AppException(
          code: 'permission-denied',
          message: 'Notification permission permanently denied',
          userMessage: 'Please enable notifications in your device settings.',
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(
          error.userMessage,
          equals('Please enable notifications in your device settings.'),
        );
      });

      test('maps statusCode when present', () {
        const exception = AppException(
          code: 'auth-error',
          message: 'Server returned 401',
          userMessage: 'Your session has expired.',
          statusCode: 401,
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error.statusCode, equals(401));
      });

      test('statusCode is null when not provided', () {
        const exception = AppException(
          code: 'local-error',
          message: 'Local operation failed',
          userMessage: 'Something went wrong locally.',
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error.statusCode, isNull);
      });

      test('returns an ApiError instance', () {
        const exception = AppException(
          code: 'test',
          message: 'Test message',
          userMessage: 'Test user message',
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error, isA<ApiError>());
      });

      test('all fields are preserved end-to-end', () {
        const exception = AppException(
          code: 'incident-save-failed',
          message: 'Hive write failed for incident box',
          userMessage: 'Could not record the incident. Please try again.',
          statusCode: 500,
        );

        final error = AppErrorMapper.toApiError(exception);

        expect(error.code, equals(exception.code));
        expect(error.message, equals(exception.message));
        expect(error.userMessage, equals(exception.userMessage));
        expect(error.statusCode, equals(exception.statusCode));
      });

      test('handles AppException with cause field set', () {
        final cause = Exception('Underlying IO error');
        final exception = AppException(
          code: 'io-error',
          message: 'Failed to write to disk',
          userMessage: 'Storage is unavailable.',
          cause: cause,
        );

        // The cause is internal — it must not leak into the ApiError.
        final error = AppErrorMapper.toApiError(exception);

        expect(error.code, equals('io-error'));
        expect(error.userMessage, equals('Storage is unavailable.'));
      });
    });

    // ── toApiError — generic Exception input ──────────────────────────────────

    group('toApiError with generic Exception', () {
      test('code is "unknown" for a plain Exception', () {
        final error = AppErrorMapper.toApiError(Exception('Something failed'));

        expect(error.code, equals('unknown'));
      });

      test('userMessage is a safe fallback for a plain Exception', () {
        final error = AppErrorMapper.toApiError(Exception('Something failed'));

        expect(
            error.userMessage, equals('Unexpected error. Please try again.'));
      });

      test('message contains the exception toString for a plain Exception', () {
        final exception = Exception('Disk full');
        final error = AppErrorMapper.toApiError(exception);

        expect(error.message, contains('Disk full'));
      });

      test('code is "unknown" for a StateError', () {
        final error = AppErrorMapper.toApiError(
          StateError('Used before initialisation'),
        );

        expect(error.code, equals('unknown'));
      });

      test('code is "unknown" for a FormatException', () {
        final error = AppErrorMapper.toApiError(
          const FormatException('Invalid JSON at position 0'),
        );

        expect(error.code, equals('unknown'));
      });

      test('code is "unknown" for a RangeError', () {
        final error =
            AppErrorMapper.toApiError(RangeError('Index out of range'));

        expect(error.code, equals('unknown'));
      });

      test('code is "unknown" for a TypeError', () {
        // Simulate a cast failure represented as a generic object.
        final error = AppErrorMapper.toApiError(TypeError());

        expect(error.code, equals('unknown'));
      });

      test('returns an ApiError instance for any input type', () {
        final inputs = <Object>[
          Exception('generic'),
          StateError('state'),
          const FormatException('format'),
          ArgumentError('arg'),
          'a plain string error',
          42,
        ];

        for (final input in inputs) {
          final error = AppErrorMapper.toApiError(input);
          expect(error, isA<ApiError>(), reason: 'Failed for input: $input');
        }
      });

      test('statusCode is null for a generic Exception', () {
        final error = AppErrorMapper.toApiError(Exception('no status'));

        expect(error.statusCode, isNull);
      });

      test('userMessage is never empty for any input', () {
        final inputs = <Object>[
          Exception('test'),
          StateError('state'),
          'raw string',
        ];

        for (final input in inputs) {
          final error = AppErrorMapper.toApiError(input);
          expect(
            error.userMessage,
            isNotEmpty,
            reason: 'userMessage was empty for input: $input',
          );
        }
      });
    });

    // ── AppException.toString ─────────────────────────────────────────────────

    group('AppException.toString', () {
      test('includes code', () {
        const exception = AppException(
          code: 'my-code',
          message: 'Details here',
          userMessage: 'Safe message',
        );

        expect(exception.toString(), contains('my-code'));
      });

      test('includes message', () {
        const exception = AppException(
          code: 'code',
          message: 'Technical details',
          userMessage: 'Safe message',
        );

        expect(exception.toString(), contains('Technical details'));
      });

      test('includes statusCode when present', () {
        const exception = AppException(
          code: 'code',
          message: 'message',
          userMessage: 'safe',
          statusCode: 404,
        );

        expect(exception.toString(), contains('404'));
      });

      test('does not throw when statusCode is null', () {
        const exception = AppException(
          code: 'code',
          message: 'message',
          userMessage: 'safe',
        );

        expect(() => exception.toString(), returnsNormally);
      });
    });
  });
}
