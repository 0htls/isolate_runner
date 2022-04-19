import 'dart:async';
import 'dart:isolate';

import 'methods.dart';
import 'error.dart';
import 'ports.dart';

abstract class _ChannelBase<T> {
  _ChannelBase() {
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

class SingleResultChannel<R> extends _ChannelBase<Object?> {
  SendPort get sendPort => _receivePort.sendPort;

  ResultPort<R> get resultPort => ResultPort(sendPort);

  final _resultCompleter = Completer<R>();

  Future<R> get result => _resultCompleter.future;

  @override
  void _handleMessage(Object? message) {
    close();
    assert(!_resultCompleter.isCompleted);

    if (message is! MethodResult<R>) {
      _resultCompleter.completeError(IsolateRunnerError('$message is! MethodResult'));
    } else {
      if (message.hasError) {
        _resultCompleter.completeError(
          message.error,
          message.stackTrace,
        );
      } else {
        _resultCompleter.complete(message.value);
      }
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
        resultPort.success(await result);
      } else {
        resultPort.success(result);
      }
    } catch (error, stackTrace) {
      resultPort.error(error, stackTrace);
    }
  }
}

class MethodChannel extends _ChannelBase<MethodConfiguration> {
  MethodPort get methodPort => MethodPort(_receivePort.sendPort);

  @override
  void _handleMessage(MethodConfiguration message) {
    message.apply(this);
  }
}
