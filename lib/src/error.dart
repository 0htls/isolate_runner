class IsolateRunnerError extends Error {
  IsolateRunnerError(this.message);

  final String message;

  @override
  String toString() => message;
}
