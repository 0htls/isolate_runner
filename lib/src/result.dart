abstract class ChannelResult {}

class OK<R> extends ChannelResult {
  OK(this.value);

  final R value;
}

class Err extends ChannelResult {
  Err({
    required this.error,
    required this.stackTrace,
  });

  final String error;

  final String stackTrace;
}
