import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'error.dart';
import 'port.dart';
import 'methods.dart';

abstract class IsolateRunner {
  factory IsolateRunner({String? debugName}) {
    return _LazyIsolateRunner(debugName: debugName);
  }

  static Future<IsolateRunner> spawn({String? debugName}) async {
    final resultChannel = SingleResultChannel<MethodPort>();
    final pingChannel = SingleResultChannel();

    final isolate = await Isolate.spawn<ResultPort>(
      MethodChannel.create,
      resultChannel.channelPort,
      debugName: debugName,
    );
    isolate.setErrorsFatal(false);
    isolate.ping(pingChannel.sendPort);

    final methodPort = await resultChannel.result;
    // Ensure setErrorsFatal has completed.
    await pingChannel.result;

    return _SingleIsolateRunner(
      isolate: isolate,
      methodPort: methodPort,
    );
  }

  bool get isClosed;

  Future<R> run<R>(IsolateRunnerCallback<R> callback);

  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args,
  );

  Future<void> close();

  /// [Isolate.kill] Isolate.kill(priority: Isolate.immediate)
  Future<void> kill();
}

Never _throwAlreadyClosedError() {
  throw IsolateRunnerError('This runner already closed.');
}

class _SingleIsolateRunner implements IsolateRunner {
  _SingleIsolateRunner({
    required Isolate isolate,
    required MethodPort methodPort,
  })  : _isolate = isolate,
        _methodPort = methodPort;

  final Isolate _isolate;

  final MethodPort _methodPort;

  var _isClosed = false;

  @override
  bool get isClosed => _isClosed;

  @override
  Future<R> run<R>(IsolateRunnerCallback<R> callback) {
    if (isClosed) {
      _throwAlreadyClosedError();
    }

    return _methodPort.invokeMethod<R>(RunMethod<R>(callback));
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args,
  ) {
    if (isClosed) {
      _throwAlreadyClosedError();
    }

    return _methodPort.invokeMethod<R>(RunWithArgsMethod(callback, args));
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

class _LazyIsolateRunner implements IsolateRunner {
  _LazyIsolateRunner({this.debugName});

  final String? debugName;

  var _isClosed = false;

  @override
  bool get isClosed => _isClosed;

  _SingleIsolateRunner? _runner;

  Future<void>? _initialized;

  Future<void> _ensureRunnerInitialized() async {
    if (_initialized == null) {
      final completer = Completer<void>();
      _initialized = completer.future;
      _runner = (await IsolateRunner.spawn(
        debugName: debugName,
      )) as _SingleIsolateRunner;
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
    await _runner?.close();
    _runner = null;
  }

  @override
  Future<R> run<R>(IsolateRunnerCallback<R> callback) async {
    if (_isClosed) {
      _throwAlreadyClosedError();
    }

    if (_runner != null) {
      return _runner!.run<R>(callback);
    }

    await _ensureRunnerInitialized();
    return _runner!.run<R>(callback);
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args,
  ) async {
    if (_isClosed) {
      _throwAlreadyClosedError();
    }

    if (_runner != null) {
      return _runner!.runWithArgs<R, A>(callback, args);
    }

    await _ensureRunnerInitialized();
    return _runner!.runWithArgs<R, A>(callback, args);
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
    await _runner?.kill();
    _runner = null;
  }
}
