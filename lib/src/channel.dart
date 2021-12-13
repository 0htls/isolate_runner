import 'dart:async';
import 'dart:isolate';

import 'package:isolate_executor/src/port.dart';
import 'package:isolate_executor/src/result.dart';

import 'methods.dart';
import 'error.dart';
import 'port.dart';

abstract class Channel<T> {
  Channel() {
    _receivePort.handler = _handleMessage;
  }

  final _receivePort = RawReceivePort();

  ChannelPort<T> get channelPort;

  void _handleMessage(T message);

  void close() {
    _receivePort.close();
  }
} 

class SingleResultChannel<R> extends Channel<Object?> {

  SendPort get sendPort => _receivePort.sendPort;

  @override
  ResultPort get channelPort => ResultPort(sendPort);

  final _resultCompleter = Completer<R>();

  Future<R> get result => _resultCompleter.future;

  @override
  void _handleMessage(Object? message) {
    close();

    assert(!_resultCompleter.isCompleted);

    if (message is OK<R>) {
      _resultCompleter.complete(message.value);
    } else if (message is Err) {
      _resultCompleter.completeError(
        IsolateExecutorError(message.error),
        StackTrace.fromString(message.stackTrace),
      );
    } else {
      _resultCompleter.complete(message as R);
    }
  }
  
}

class MethodChannel extends Channel<MethodConfiguration> {
  MethodChannel._();

  static void create(ResultPort result) {
    final channel = MethodChannel._();
    result.ok(channel.channelPort);
  }

    @override
  MethodPort get channelPort => MethodPort(_receivePort.sendPort);

  @override
  void _handleMessage(MethodConfiguration message) {
    message.apply(this);
  }
}


