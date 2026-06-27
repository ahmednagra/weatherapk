import '../errors/failures.dart';

/// Lightweight Either: a success [Ok] or a [Err] carrying a [Failure].
/// Keeps the domain free of exceptions without pulling in dartz.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
