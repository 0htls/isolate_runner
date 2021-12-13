import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'methods.dart';
import 'result.dart';

class ChannelPort<T> {
  ChannelPort(this._sendPort);

  final SendPort _sendPort;

  void _send(T value) {
    _sendPort.send(value);
  }
}

typedef ResultPort = ChannelPort<ChannelResult>;

extension ResultPortExtenson on ResultPort {
  void ok<R>(R value) {
    _send(OK(value));
  }

  void err<E extends Object>(E error, StackTrace stackTrace) {
    _send(Err(
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    ));
  }
}

typedef MethodPort = ChannelPort<MethodConfiguration>;

extension MethodPortExtension on MethodPort {
  Future<R> invokeMethod<R>(ChannelMethod method) {
    final resultChannel = SingleResultChannel<R>();
    _send(MethodConfiguration(
      method: method,
      resultPort: resultChannel.channelPort,
    ));
    return resultChannel.result;
  }
}
