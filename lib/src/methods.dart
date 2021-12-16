import 'dart:async';

import 'port.dart';
import 'channel.dart' show MethodChannel;

typedef IsolateExecutorCallback<R> = FutureOr<R> Function();

typedef IsolateExecutorCallbackWithArg<R, A> = FutureOr<R> Function(A arg);

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

  final IsolateExecutorCallback<R> callback;

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    Future.sync(callback).then<void>((value) {
      result.ok(value);
    }).onError<Object>((error, stackTrace) {
      result.err(error, stackTrace);
    });
  }
}

class RunWithArgMethod<R, A> implements ChannelMethod {
  RunWithArgMethod(this.callback, this.arg);

  final IsolateExecutorCallbackWithArg<R, A> callback;

  final A arg;

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    Future.sync(() => callback(arg)).then<void>((value) {
      result.ok(value);
    }).onError<Object>((error, stackTrace) {
      result.err(error, stackTrace);
    });
  }
}
