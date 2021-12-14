import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'error.dart';
import 'port.dart';
import 'methods.dart';

abstract class IsolateExecutor {
  factory IsolateExecutor.lazy() = _LazyIsolateExecutor;

  static Future<IsolateExecutor> spawn() async {
    final resultChannel = SingleResultChannel<MethodPort>();
    final pingChannel = SingleResultChannel();

    final isolate = await Isolate.spawn<ResultPort>(
      MethodChannel.create,
      resultChannel.channelPort,
    );
    isolate.setErrorsFatal(false);
    isolate.ping(pingChannel.sendPort);

    final methodPort = await resultChannel.result;
    // Ensure setErrorsFatal has completed.
    await pingChannel.result;

    return _SingleIsolateExecutor(isolate, methodPort);
  }

  bool get isClosed;

  Future<R> execute<R>(IsolateExecutorCallback<R> callback);

  Future<R> executeWithArg<R, A>(
    IsolateExecutorCallbackWithArg<R, A> callback,
    A arg,
  );

  Future<void> close();

  Future<void> kill();
}

Never _throwAlreadyClosedError() {
  throw IsolateExecutorError('This executor already closed.');
}

class _SingleIsolateExecutor implements IsolateExecutor {
  _SingleIsolateExecutor(this._isolate, this._methodPort);

  final Isolate _isolate;

  final MethodPort _methodPort;

  var _isClosed = false;

  @override
  bool get isClosed => _isClosed;

  @override
  Future<R> execute<R>(IsolateExecutorCallback<R> callback) {
    if (isClosed) {
      _throwAlreadyClosedError();
    }

    return _methodPort.invokeMethod<R>(RunMethod<R>(callback));
  }

  @override
  Future<R> executeWithArg<R, A>(
    IsolateExecutorCallbackWithArg<R, A> callback,
    A arg,
  ) {
    if (isClosed) {
      _throwAlreadyClosedError();
    }

    return _methodPort.invokeMethod<R>(RunWithArgMethod(callback, arg));
  }

  @override
  Future<void> close() async {
    if (isClosed) {
      return;
    }

    _isClosed = true;
    await _methodPort.invokeMethod<void>(const CloseMethod());
  }

  @override
  Future<void> kill() async {
    if (isClosed) {
      return;
    }

    _isClosed = true;
    final channel = SingleResultChannel();
    _isolate.addOnExitListener(channel.sendPort);
    _isolate.kill(priority: Isolate.immediate);
    await channel.result;
  }
}

class _LazyIsolateExecutor implements IsolateExecutor {
  var _isClosed = false;

  @override
  bool get isClosed => _isClosed;

  _SingleIsolateExecutor? _executor;

  Future<void>? _initialized;

  Future<void> _ensureExecutorInitialized() async {
    if (_initialized == null) {
      final completer = Completer<void>();
      _initialized = completer.future;
      _executor = (await IsolateExecutor.spawn()) as _SingleIsolateExecutor;
      completer.complete();
    }

    await _initialized!;
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    if (_initialized != null) {
      await _initialized;
    }
    await _executor?.close();
    _executor = null;
  }

  @override
  Future<R> execute<R>(IsolateExecutorCallback<R> callback) async {
    if (_isClosed) {
      _throwAlreadyClosedError();
    }

    if (_executor != null) {
      return _executor!.execute<R>(callback);
    }

    await _ensureExecutorInitialized();
    return _executor!.execute<R>(callback);
  }

  @override
  Future<R> executeWithArg<R, A>(
    IsolateExecutorCallbackWithArg<R, A> callback,
    A arg,
  ) async {
    if (_isClosed) {
      _throwAlreadyClosedError();
    }

    if (_executor != null) {
      return _executor!.executeWithArg<R, A>(callback, arg);
    }

    await _ensureExecutorInitialized();
    return _executor!.executeWithArg<R, A>(callback, arg);
  }

  @override
  Future<void> kill() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    if (_initialized != null) {
      await _initialized;
    }
    await _executor?.kill();
    _executor = null;
  }
}
