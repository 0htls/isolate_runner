class IsolateExecutorError extends Error {
  IsolateExecutorError(this.message);

  final String message;

  @override
  String toString() => message;
}
