import 'package:test/test.dart';
import 'package:isolate_runner/src/channel.dart';
import 'package:isolate_runner/src/port.dart';
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
    channel.channelPort.ok(100);
    expect(await channel.result, 100);
    expect(channel.isClosed, true);
  });

  test('result error', () async {
    final channel = SingleResultChannel();
    expect(channel.isClosed, false);
    channel.channelPort.err(
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

class _TestMethod implements ChannelMethod {
  _TestMethod(this.value);

  final Object? value;

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    result.ok(value);
  }
}

class _CloseMethod implements ChannelMethod {
  _CloseMethod();

  @override
  void call(ResultPort result, MethodChannel methodChannel) {
    result.ok(methodChannel.isClosed);
  }
}

Future<void> testMethodChannel() async {
  final resultChannel = SingleResultChannel<MethodPort>();
  MethodChannel.create(resultChannel.channelPort);
  final methodPort = await resultChannel.result;

  Object? result = await methodPort.invokeMethod(_TestMethod(100));
  expect(result, 100);

  result = await methodPort.invokeMethod(_CloseMethod());
  expect(result, isFalse);
}
