import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'methods.dart';

class MethodResult<T> {
  MethodResult.success(T value) : _value = value;

  MethodResult.error(Object error, StackTrace stackTrace)
      : _error = error,
        _stackTrace = stackTrace;

  T? _value;
  T get value {
    assert(!hasError);
    return _value!;
  }

  Object? _error;
  Object get error => _error!;
  StackTrace? _stackTrace;
  StackTrace get stackTrace => _stackTrace!;
  bool get hasError => _error != null && _stackTrace != null;
}

class ResultPort<R> {
  ResultPort(this._sendPort);

  final SendPort _sendPort;

  void success(R value) {
    _sendPort.send(MethodResult.success(value));
  }

  void error(Object error, StackTrace stackTrace) {
    _sendPort.send(MethodResult.error(error, stackTrace));
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
