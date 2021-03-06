import 'dart:async';
import 'dart:isolate';

import 'channel.dart';
import 'methods.dart';
import 'ports.dart';
import 'error.dart';

class MethodInvoker {
  MethodInvoker({this.debugName});

  final String? debugName;

  Isolate? _isolate;

  MethodPort? _methodPort;

  bool _isClosed = false;
  bool get isClosed => _isClosed;

  int _load = 0;
  int get load => _load;

  Future<void>? _future;

  static void _createMethodChannel(ResultPort result) {
    final channel = MethodChannel();
    result.success(channel.methodPort);
  }

  Future<void> _initialize() async {
    final resultChannel = SingleResultChannel<MethodPort>();
    _isolate = await Isolate.spawn<ResultPort>(
      _createMethodChannel,
      resultChannel.resultPort,
      debugName: debugName,
      errorsAreFatal: false,
    );
    _methodPort = await resultChannel.result;
  }

  Future<void> _ensureInitialized() {
    _future ??= _initialize();
    return _future!;
  }

  Future<R> invoke<R>(Method<R> method, {int load = 1}) async {
    if (isClosed) {
      throw IsolateRunnerError('This invoker already closed.');
    }

    if (_methodPort != null) {
      return _methodPort!.sendMethodForResult(method);
    }

    await _ensureInitialized();
    _load += load;
    return _methodPort!.sendMethodForResult(method).whenComplete(() {
      _load -= load;
    });
  }

  Future<void> close({bool immediate = false}) async {
    if (isClosed) {
      return;
    }

    _isClosed = true;
    if (_isolate == null && _future == null) {
      return;
    }

    if (_isolate == null) {
      assert(_future != null);
      await _future;
    }

    assert(_isolate != null && _methodPort != null);

    if (immediate) {
      final channel = SingleResultChannel();
      _isolate!.addOnExitListener(channel.sendPort);
      _isolate!.kill(priority: Isolate.immediate);
      await channel.result;
    } else {
      await _methodPort!.sendMethodForResult(const Close());
    }
  }
}
