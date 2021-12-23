import 'dart:async';

import 'package:test/test.dart';

import 'package:isolate_runner/isolate_runner.dart';

void main() {
  group('IsolateRunner', () => testIsolateRunner(IsolateRunner.new));
  group('SingleIsolateRunner', () => testIsolateRunner(IsolateRunner.new));
  group('MultiIsolateRunner', testMultiIsolateRunner);
}

void testIsolateRunner(FutureOr<IsolateRunner> Function() createRunner) {
  test('close', () async {
    final runner = await createRunner();
    expect(runner.isClosed, false);
    runner.close();
    expect(runner.isClosed, true);
  });

  test('run', () async {
    final runner = await createRunner();

    Object? result;
    result = await runner.run(() => null);
    expect(result, null);

    result = await runner.run(() => 100);
    expect(result, 100);

    result = await runner.run(() => 'IsolateRunner');
    expect(result, 'IsolateRunner');

    runner.close();
  });
}

void testMultiIsolateRunner() {
  test('fib', () async {
    final runner = IsolateRunner.multi(debugName: 'Runner', size: 5);
    for (var i = 0; i < 10; i++) {
      runner.runWithArgs(fib, 10 + i).then((value) {
        print('fib => $value');
      });
    }
    await runner.close();
    expect(runner.isClosed, isTrue);
  });
}

int fib(int x) {
  return x < 2 ? x : fib(x - 1) + fib(x - 2);
}
