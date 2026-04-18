import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/shared/models/api_error.dart';
import 'package:senior_companion/shared/models/app_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _testError = ApiError(
  code: 'test-error',
  message: 'Technical error message',
  userMessage: 'Something went wrong. Please try again.',
  statusCode: 422,
);

const _networkError = ApiError(
  code: 'network-timeout',
  message: 'Connection timed out after 10s',
  userMessage: 'Connection issue. Please check your network.',
);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AppResult', () {
    // ── Success ───────────────────────────────────────────────────────────────

    group('AppResult.success', () {
      test('isSuccess returns true', () {
        final result = AppResult.success(42);
        expect(result.isSuccess, isTrue);
      });

      test('isFailure returns false', () {
        final result = AppResult.success('hello');
        expect(result.isFailure, isFalse);
      });

      test('runtime type is Success', () {
        final result = AppResult.success(42);
        expect(result, isA<Success<int>>());
      });

      test('value is accessible via cast to Success', () {
        final result = AppResult.success('hello') as Success<String>;
        expect(result.value, equals('hello'));
      });

      test('getOrNull returns the wrapped value', () {
        final result = AppResult.success(99);
        expect(result.getOrNull(), equals(99));
      });

      test('getOrNull returns null literal correctly when value is zero', () {
        // Ensures getOrNull does not confuse falsy values with absence.
        final result = AppResult.success(0);
        expect(result.getOrNull(), equals(0));
        expect(result.getOrNull(), isNotNull);
      });

      test('getOrNull returns null literal correctly when value is false', () {
        final result = AppResult.success(false);
        expect(result.getOrNull(), equals(false));
        expect(result.getOrNull(), isNotNull);
      });

      test('when() dispatches to the success branch', () {
        final result = AppResult.success(10);
        final output = result.when(
          success: (value) => 'got $value',
          failure: (_) => 'failed',
        );
        expect(output, equals('got 10'));
      });

      test('when() does not call the failure branch', () {
        final result = AppResult.success(42);
        bool failureCalled = false;

        result.when(
          success: (_) => 'ok',
          failure: (_) {
            failureCalled = true;
            return 'fail';
          },
        );

        expect(failureCalled, isFalse);
      });

      test('when() returns the value produced by the success handler', () {
        final result = AppResult.success([1, 2, 3]);
        final count = result.when(
          success: (list) => list.length,
          failure: (_) => -1,
        );
        expect(count, equals(3));
      });

      test('works with String type', () {
        final result = AppResult.success('Senior Companion');
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('Senior Companion'));
      });

      test('works with nullable inner type', () {
        final result = AppResult.success<String?>(null);
        expect(result.isSuccess, isTrue);
        // getOrNull returns null because the value IS null — not a failure.
        // The distinction between failure and success-with-null is
        // in the isSuccess flag, not in getOrNull alone.
        expect(result.isFailure, isFalse);
      });

      test('works with List type', () {
        final result = AppResult.success(<String>['a', 'b']);
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(['a', 'b']));
      });

      test('equality: two Success with same value are equal', () {
        final a = AppResult.success(42) as Success<int>;
        final b = AppResult.success(42) as Success<int>;
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equality: two Success with different values are not equal', () {
        final a = AppResult.success(1) as Success<int>;
        final b = AppResult.success(2) as Success<int>;
        expect(a, isNot(equals(b)));
      });

      test('toString contains type and value', () {
        final result = AppResult.success(7) as Success<int>;
        expect(result.toString(), contains('Success'));
        expect(result.toString(), contains('7'));
      });
    });

    // ── Failure ───────────────────────────────────────────────────────────────

    group('AppResult.failure', () {
      test('isSuccess returns false', () {
        final result = AppResult.failure<int>(_testError);
        expect(result.isSuccess, isFalse);
      });

      test('isFailure returns true', () {
        final result = AppResult.failure<int>(_testError);
        expect(result.isFailure, isTrue);
      });

      test('runtime type is Failure', () {
        final result = AppResult.failure<int>(_testError);
        expect(result, isA<Failure<int>>());
      });

      test('error is accessible via cast to Failure', () {
        final result = AppResult.failure<int>(_testError) as Failure<int>;
        expect(result.error.code, equals('test-error'));
        expect(result.error.message, equals('Technical error message'));
        expect(result.error.userMessage,
            equals('Something went wrong. Please try again.'));
        expect(result.error.statusCode, equals(422));
      });

      test('getOrNull returns null on failure', () {
        final result = AppResult.failure<int>(_testError);
        expect(result.getOrNull(), isNull);
      });

      test('when() dispatches to the failure branch', () {
        final result = AppResult.failure<int>(_testError);
        final output = result.when(
          success: (value) => 'got $value',
          failure: (error) => 'failed: ${error.code}',
        );
        expect(output, equals('failed: test-error'));
      });

      test('when() does not call the success branch', () {
        final result = AppResult.failure<int>(_testError);
        bool successCalled = false;

        result.when(
          success: (_) {
            successCalled = true;
            return 'ok';
          },
          failure: (_) => 'fail',
        );

        expect(successCalled, isFalse);
      });

      test('when() passes the full ApiError to the failure handler', () {
        final result = AppResult.failure<String>(_networkError);
        ApiError? captured;

        result.when(
          success: (_) => null,
          failure: (error) {
            captured = error;
            return null;
          },
        );

        expect(captured, isNotNull);
        expect(captured!.code, equals('network-timeout'));
        expect(captured!.statusCode, isNull);
      });

      test('works with any generic type parameter', () {
        final result = AppResult.failure<List<String>>(_testError);
        expect(result.isFailure, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('equality: two Failure with same error code are equal', () {
        final a = AppResult.failure<int>(_testError) as Failure<int>;
        final b = AppResult.failure<int>(_testError) as Failure<int>;
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equality: two Failure with different error codes are not equal',
          () {
        final a = AppResult.failure<int>(_testError) as Failure<int>;
        final b = AppResult.failure<int>(_networkError) as Failure<int>;
        expect(a, isNot(equals(b)));
      });

      test('toString contains Failure and error code', () {
        final result = AppResult.failure<int>(_testError) as Failure<int>;
        expect(result.toString(), contains('Failure'));
        expect(result.toString(), contains('test-error'));
      });
    });

    // ── when() return type ────────────────────────────────────────────────────

    group('when() return type flexibility', () {
      test('can return int', () {
        final result = AppResult.success(5);
        final doubled = result.when(
          success: (v) => v * 2,
          failure: (_) => 0,
        );
        expect(doubled, equals(10));
      });

      test('can return bool', () {
        final result = AppResult.failure<String>(_testError);
        final ok = result.when(
          success: (_) => true,
          failure: (_) => false,
        );
        expect(ok, isFalse);
      });

      test('can return null (nullable return type)', () {
        final result = AppResult.success('data');
        final output = result.when<String?>(
          success: (v) => v,
          failure: (_) => null,
        );
        expect(output, equals('data'));
      });

      test('can execute side effects in success branch', () {
        final result = AppResult.success(42);
        final sideEffects = <String>[];

        result.when(
          success: (v) => sideEffects.add('success: $v'),
          failure: (e) => sideEffects.add('failure: ${e.code}'),
        );

        expect(sideEffects, equals(['success: 42']));
      });

      test('can execute side effects in failure branch', () {
        final result = AppResult.failure<int>(_testError);
        final sideEffects = <String>[];

        result.when(
          success: (v) => sideEffects.add('success: $v'),
          failure: (e) => sideEffects.add('failure: ${e.code}'),
        );

        expect(sideEffects, equals(['failure: test-error']));
      });
    });

    // ── Static factory contracts ───────────────────────────────────────────────

    group('static factory contracts', () {
      test('AppResult.success<T> infers T from the argument', () {
        final result = AppResult.success('hello');
        // If this compiles without explicit type annotation, inference works.
        expect(result, isA<AppResult<String>>());
      });

      test('AppResult.failure<T> requires explicit T when context is absent',
          () {
        final result = AppResult.failure<double>(_testError);
        expect(result, isA<AppResult<double>>());
        expect(result, isA<Failure<double>>());
      });

      test('success and failure are never equal to each other', () {
        final success = AppResult.success(1);
        final failure = AppResult.failure<int>(_testError);
        expect(success, isNot(equals(failure)));
      });
    });
  });
}
