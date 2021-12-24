import 'dart:async';

import 'methods.dart';
import 'runner.dart';

abstract class IsolateRunner {
  factory IsolateRunner({
    String? debugName,
  }) = _SingleRunner;

  /// The [size] is the number of isolates.
  factory IsolateRunner.multi({
    String? debugName,
    int size,
  }) = _MultiRunner;

  bool get isClosed;

  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 1,
  });

  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 1,
  });

  Future<void> close({bool immediate = false});
}

class _SingleRunner implements IsolateRunner {
  _SingleRunner({
    String? debugName,
  }) : _runner = Runner(debugName: debugName);

  final Runner _runner;

  @override
  bool get isClosed => _runner.isClosed;

  @override
  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 1,
  }) {
    return _runner.run(Run<R>(callback));
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 1,
  }) {
    return _runner.run(RunWithArgs(
      callback,
      args,
    ));
  }

  @override
  Future<void> close({bool immediate = false}) {
    return _runner.close(immediate: immediate);
  }
}

extension _StatefulRunners on List<StatefulRunner> {
  StatefulRunner getLeastLoadedRunner() {
    var currentRunner = first;
    if (currentRunner.load == 0) {
      return currentRunner;
    }

    for (var i = 1; i < length; i++) {
      final runner = this[i];
      if (runner.load == 0) {
        return runner;
      }

      if (runner.load < currentRunner.load) {
        currentRunner = runner;
      }
    }

    return currentRunner;
  }
}

class _MultiRunner implements IsolateRunner {
  _MultiRunner({
    String? debugName,
    int size = 1,
  }) {
    assert(size >= 1);

    _runners = List.generate(
      size,
      (index) {
        return StatefulRunner(
          debugName: debugName == null ? null : '$debugName ($index)',
        );
      },
      growable: false,
    );
  }

  late final List<StatefulRunner> _runners;

  @override
  Future<void> close({bool immediate = false}) async {
    for (final runner in _runners) {
      await runner.close(immediate: immediate);
    }
  }

  @override
  bool get isClosed => _runners.first.isClosed;

  Future<R> _run<R>(Method<R> method, int load) {
    final runner = _runners.getLeastLoadedRunner();
    return runner.run(method, load: load);
  }

  @override
  Future<R> run<R>(
    IsolateRunnerCallback<R> callback, {
    int load = 1,
  }) {
    return _run(Run(callback), load);
  }

  @override
  Future<R> runWithArgs<R, A>(
    IsolateRunnerCallbackWithArgs<R, A> callback,
    A args, {
    int load = 1,
  }) {
    return _run(RunWithArgs(callback, args), load);
  }
}
