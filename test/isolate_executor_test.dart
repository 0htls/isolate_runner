import 'dart:async';

import 'package:test/test.dart';

import 'package:isolate_executor/isolate_executor.dart';

void main() {
  group('IsolateExecutor', () => testIsolateExecutor(IsolateExecutor.spawn));
  group('LazyIsolateExecutor', () => testIsolateExecutor(IsolateExecutor.lazy));
}

void testIsolateExecutor(FutureOr<IsolateExecutor> Function() createExecutor) {
  test('close', () async {
    final executor = await createExecutor();
    expect(executor.isClosed, false);
    executor.close();
    expect(executor.isClosed, true);
  });

  test('kill', () async {
    final executor = await createExecutor();
    executor.kill();
  });

  test('execute', () async {
    final executor = await createExecutor();

    Object? result;
    result = await executor.execute(() => null);
    expect(result, null);

    result = await executor.execute(() => 100);
    expect(result, 100);

    result = await executor.execute(() => 'IsolateExecutor');
    expect(result, 'IsolateExecutor');

    executor.close();
  });
}
