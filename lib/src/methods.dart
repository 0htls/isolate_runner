import 'dart:async';

import 'port.dart';
import 'channel.dart' show MethodChannel;

typedef IsolateRunnerCallback<R> = FutureOr<R> Function();

typedef IsolateRunnerCallbackWithArgs<R, A> = FutureOr<R> Function(A args);

abstract class ChannelMethod {
  const ChannelMethod();

  void call(ResultPort result, MethodChannel methodChannel);
}

class CloseMethod implements ChannelMethod {
  const CloseMethod();

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    methodChannel.close();
    result.ok(null);
  }
}

class RunMethod<R> implements ChannelMethod {
  RunMethod(this.callback);

  final IsolateRunnerCallback<R> callback;

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    Future.sync(callback).then<void>((value) {
      result.ok(value);
    }).onError<Object>((error, stackTrace) {
      result.err(error, stackTrace);
    });
  }
}

class RunWithArgsMethod<R, A> implements ChannelMethod {
  RunWithArgsMethod(this.callback, this.args);

  final IsolateRunnerCallbackWithArgs<R, A> callback;

  final A args;

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    Future.sync(() => callback(args)).then<void>((value) {
      result.ok(value);
    }).onError<Object>((error, stackTrace) {
      result.err(error, stackTrace);
    });
  }
}
