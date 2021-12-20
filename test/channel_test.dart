import 'dart:async';

import 'package:test/test.dart';
import 'package:isolate_runner/src/channel.dart';
import 'package:isolate_runner/src/methods.dart';

void main() {
  test('MethodChannel', testMethodChannel);
  group('SingleResultChannel', testSingleResultChannel);
}

void testSingleResultChannel() {
  test('result sendPort', () async {
    final channel = SingleResultChannel<int>();
    channel.sendPort.send(9899);
    expect(await channel.result, 9899);
  });

  test('result ok', () async {
    final channel = SingleResultChannel<int>();
    expect(channel.isClosed, false);
    channel.resultPort.ok(100);
    expect(await channel.result, 100);
    expect(channel.isClosed, true);
  });

  test('result error', () async {
    final channel = SingleResultChannel();
    expect(channel.isClosed, false);
    channel.resultPort.err(
      StateError('channelPort.error'),
      StackTrace.current,
    );
    try {
      await channel.result;
      fail('should throw');
    } catch (error) {
      expect(channel.isClosed, true);
    }
  });
}

class _TestMethod implements Method<Object?> {
  _TestMethod(this.value);

  final Object? value;

  @override
  Object? call(MethodChannel methodChannel) {
    return value;
  }
}

class _CloseMethod implements Method<bool> {
  _CloseMethod();

  @override
  bool call(MethodChannel methodChannel) {
    return methodChannel.isClosed;
  }
}

Future<void> testMethodChannel() async {
  final methodChannel = MethodChannel();
  final methodPort = methodChannel.methodPort;

  Object? result = await methodPort.sendMethodForResult(_TestMethod(100));
  expect(result, 100);

  result = await methodPort.sendMethodForResult(_CloseMethod());
  expect(result, isFalse);
}
