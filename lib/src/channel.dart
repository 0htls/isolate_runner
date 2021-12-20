import 'dart:async';
import 'dart:isolate';

import 'methods.dart';
import 'result.dart';
import 'error.dart';
import 'ports.dart';

abstract class ChannelBase<T> {
  ChannelBase() {
    _receivePort.handler = _handleMessage;
  }

  bool _isClosed = false;
  bool get isClosed => _isClosed;

  final _receivePort = RawReceivePort();

  void _handleMessage(T message);

  void close() {
    _receivePort.close();
    _isClosed = true;
  }
}

class SingleResultChannel<R> extends ChannelBase<Object?> {
  SendPort get sendPort => _receivePort.sendPort;

  ResultPort<R> get resultPort => ResultPort(sendPort);

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
        IsolateRunnerError(message.error),
        StackTrace.fromString(message.stackTrace),
      );
    } else {
      _resultCompleter.complete(message as R);
    }
  }
}

class MethodConfiguration<R> {
  MethodConfiguration({
    required this.method,
    required this.resultPort,
  });

  final Method<R> method;

  final ResultPort<R> resultPort;

  Future<void> apply(MethodChannel methodChannel) async {
    try {
      final result = method(methodChannel);
      if (result is Future<R>) {
        resultPort.ok(await result);
      } else {
        resultPort.ok(result);
      }
    } catch (error, stackTrace) {
      resultPort.err(error, stackTrace);
    }
  }
}

class MethodChannel extends ChannelBase<MethodConfiguration> {
  MethodPort get methodPort => MethodPort(_receivePort.sendPort);

  @override
  void _handleMessage(MethodConfiguration message) {
    message.apply(this);
  }
}
