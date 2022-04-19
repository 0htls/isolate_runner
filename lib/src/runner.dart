import 'dart:async';

import 'methods.dart';
import 'invoker.dart';

abstract class IsolateRunner {
  factory IsolateRunner({
    String? debugName,
  }) = _SingleIsolateRunner;

  /// The [size] is the number of isolates.
  factory IsolateRunner.multi({
    String? debugName,
    int size,
  }) = _MultiIsolateRunner;

  bool get isClosed;

  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 100,
  });

  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 100,
  });

  Future<void> close({bool immediate = false});
}

class _SingleIsolateRunner implements IsolateRunner {
  _SingleIsolateRunner({
    String? debugName,
  }) : _invoker = MethodInvoker(debugName: debugName);

  final MethodInvoker _invoker;

  @override
  bool get isClosed => _invoker.isClosed;

  @override
  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 100,
  }) {
    return _invoker.invoke(Run<R>(callback));
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 100,
  }) {
    return _invoker.invoke(RunWithArgs(
      callback,
      args,
    ));
  }

  @override
  Future<void> close({bool immediate = false}) {
    return _invoker.close(immediate: immediate);
  }
}

extension _SingleIsolatesExtension on List<_SingleIsolateRunner> {
  _SingleIsolateRunner get leastLoadedRunner {
    var runner = first;
    if (runner._invoker.load == 0) {
      return runner;
    }

    for (var i = 1; i < length; i++) {
      final current = this[i];
      if (current._invoker.load == 0) {
        return current;
      }
      if (current._invoker.load < runner._invoker.load) {
        runner = current;
      }
    }
    return runner;
  }
}

class _MultiIsolateRunner implements IsolateRunner {
  _MultiIsolateRunner({
    String? debugName,
    int size = 1,
  }) : _runners = List.generate(
          size,
          (index) {
            return _SingleIsolateRunner(
              debugName: debugName == null ? null : '$debugName($index)',
            );
          },
          growable: false,
        );

  final List<_SingleIsolateRunner> _runners;

  @override
  Future<void> close({bool immediate = false}) async {
    for (final runner in _runners) {
      await runner.close(immediate: immediate);
    }
  }

  @override
  bool get isClosed {
    for (final runner in _runners) {
      if (!runner.isClosed) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 100,
  }) {
    return _runners.leastLoadedRunner.run(callback, load: load);
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 100,
  }) {
    return _runners.leastLoadedRunner.runWithArgs(callback, args, load: load);
  }
}
