class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class MissingApiKeyFailure extends AppFailure {
  const MissingApiKeyFailure(super.message);
}

class StreamResolutionFailure extends AppFailure {
  const StreamResolutionFailure(super.message, {super.cause});
}
