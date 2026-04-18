import 'package:senior_companion/shared/models/api_error.dart';

/// A type-safe result wrapper for operations that can either succeed or fail.
///
/// Use the static factories to create instances:
/// ```dart
/// final result = AppResult.success(42);
/// final result = AppResult<int>.failure(ApiError(...));
/// ```
///
/// Consume results safely with [when] for exhaustive handling:
/// ```dart
/// result.when(
///   success: (value) => print('Got: $value'),
///   failure: (error) => print('Error: ${error.userMessage}'),
/// );
/// ```
sealed class AppResult<T> {
  const AppResult();

  /// Returns true if this result represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this result represents a failed outcome.
  bool get isFailure => this is Failure<T>;

  /// Returns the success value, or null if this is a [Failure].
  ///
  /// Prefer [when] for exhaustive handling. Use this only when
  /// you explicitly want to ignore the failure case.
  T? getOrNull() {
    final self = this;
    if (self is Success<T>) return self.value;
    return null;
  }

  /// Exhaustively handles both success and failure cases and returns [R].
  ///
  /// Both branches must return the same type [R].
  /// The sealed class guarantees no other subtype can exist.
  ///
  /// Example:
  /// ```dart
  /// final message = result.when(
  ///   success: (value) => 'Loaded $value items',
  ///   failure: (error) => error.userMessage,
  /// );
  /// ```
  R when<R>({
    required R Function(T value) success,
    required R Function(ApiError error) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    if (self is Failure<T>) return failure(self.error);
    // Unreachable: sealed guarantees only Success and Failure exist.
    throw StateError('Unexpected AppResult subtype: $runtimeType');
  }

  // ── Static factories ──────────────────────────────────────────────────────

  /// Creates a successful result wrapping [value].
  static AppResult<T> success<T>(T value) => Success<T>._(value);

  /// Creates a failed result wrapping [error].
  static AppResult<T> failure<T>(ApiError error) => Failure<T>._(error);
}

// ─────────────────────────────────────────────────────────────────────────────

/// A successful [AppResult] carrying a value of type [T].
final class Success<T> extends AppResult<T> {
  const Success._(this.value);

  /// The value produced by the successful operation.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.value == value);

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success<$T>($value)';
}

// ─────────────────────────────────────────────────────────────────────────────

/// A failed [AppResult] carrying an [ApiError] describing what went wrong.
final class Failure<T> extends AppResult<T> {
  const Failure._(this.error);

  /// The error that caused the operation to fail.
  final ApiError error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> &&
          other.error.code == error.code &&
          other.error.message == error.message);

  @override
  int get hashCode => Object.hash(Failure, error.code, error.message);

  @override
  String toString() => 'Failure<$T>(${error.code}: ${error.message})';
}