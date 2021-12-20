import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'methods.dart';
import 'result.dart';

class ResultPort<R> {
  ResultPort(this._sendPort);

  final SendPort _sendPort;

  void ok(R value) {
    _sendPort.send(OK(value));
  }

  void err<E extends Object>(E error, StackTrace stackTrace) {
    _sendPort.send(Err(
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    ));
  }
}

class MethodPort {
  MethodPort(this._sendPort);

  final SendPort _sendPort;

  Future<R> sendMethodForResult<R>(Method<R> method) {
    final resultChannel = SingleResultChannel<R>();
    _sendPort.send(MethodConfiguration<R>(
      method: method,
      resultPort: resultChannel.resultPort,
    ));
    return resultChannel.result;
  }
}
