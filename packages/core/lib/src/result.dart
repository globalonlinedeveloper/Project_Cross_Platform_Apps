/// Minimal functional result types shared across NIKATRU apps.
library;

/// Describes why an operation failed.
class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'Failure($message)';
}

/// A success ([Ok]) or failure ([Err]) outcome.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Collapses both cases to a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) {
    final Result<T> self = this;
    if (self is Ok<T>) {
      return onOk(self.value);
    }
    return onErr((self as Err<T>).failure);
  }
}

/// Successful result carrying a [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Failed result carrying a [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
