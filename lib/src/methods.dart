import 'dart:async';

import 'channel.dart' show MethodChannel;

typedef IsolateRunnerCallback<R> = FutureOr<R> Function();

typedef IsolateRunnerCallbackWithArgs<R, A> = FutureOr<R> Function(A args);

abstract class Method<R> {
  const Method();

  FutureOr<R> call(MethodChannel methodChannel);
}

class Close implements Method<void> {
  const Close();

  @override
  void call(MethodChannel methodChannel) {
    methodChannel.close();
  }
}

class Run<R> implements Method<R> {
  Run(this.callback);

  final IsolateRunnerCallback<R> callback;

  @override
  FutureOr<R> call(MethodChannel methodChannel) {
    return callback();
  }
}

class RunWithArgs<R, A> implements Method<R> {
  RunWithArgs(this.callback, this.args);

  final IsolateRunnerCallbackWithArgs<R, A> callback;

  final A args;

  @override
  FutureOr<R> call(MethodChannel methodChannel) {
    return callback(args);
  }
}
