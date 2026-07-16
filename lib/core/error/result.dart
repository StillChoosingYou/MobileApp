/// A minimal Result type so repositories can report failure without
/// throwing, and without pulling in a functional-programming package.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.error(String message) = Err<T>;

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(String message) error,
  }) {
    return switch (this) {
      Ok<T>(value: final v) => ok(v),
      Err<T>(message: final m) => error(m),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}
