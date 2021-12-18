import 'dart:async';

import 'package:test/test.dart';

import 'package:isolate_runner/isolate_runner.dart';

void main() {
  group('IsolateRunner', () => testIsolateRunner(IsolateRunner.spawn));
  group('LazyIsolateRunner', () => testIsolateRunner(IsolateRunner.new));
}

void testIsolateRunner(FutureOr<IsolateRunner> Function() createRunner) {
  test('close', () async {
    final runner = await createRunner();
    expect(runner.isClosed, false);
    runner.close();
    expect(runner.isClosed, true);
  });

  test('kill', () async {
    final runner = await createRunner();
    runner.kill();
  });

  test('execute', () async {
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
