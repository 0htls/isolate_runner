import 'package:test/test.dart';
import 'package:isolate_executor/src/channel.dart';
import 'package:isolate_executor/src/port.dart';
void main() {
  group('SingleResultChannel', testSingleResultChannel);
}

void testSingleResultChannel() {

  test('result sendPort', () async {
    final channel = SingleResultChannel<int>();
    channel.sendPort.send(9899);
    expect(await channel.result, 9899);
  });

  test('result channelPort.ok', () async {
    final channel = SingleResultChannel<int>();
    channel.channelPort.ok(100);
    expect(await channel.result, 100);
  });

    test('result channelPort.error', () async {
    final channel = SingleResultChannel();
    channel.channelPort.err(StateError('channelPort.error'), StackTrace.current);
    try {
      await channel.result;
      fail('should throw');
    } catch(error, stackTrace) {
      print(error.runtimeType);
    }
  });
}