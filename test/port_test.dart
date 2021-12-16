import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';

import 'package:isolate_executor/src/port.dart';
import 'package:isolate_executor/src/result.dart';
import 'package:isolate_executor/src/channel.dart' show MethodConfiguration;
import 'package:isolate_executor/src/methods.dart';

void main() {
  group('ResultPort', testResultPort);
  group('MethodPort', testMethodPort);
}

class ChannelPortTester {
  ChannelPortTester() {
    _port.handler = _handleMessage;
  }

  final _port = RawReceivePort();

  final _completer = Completer<Object?>();

  SendPort get sendPort => _port.sendPort;

  Future<Object?> get result => _completer.future;

  void _handleMessage(Object? message) {
    _port.close();
    _completer.complete(message);
  }
}

void testResultPort() {
  test('ok', () async {
    final portTester = ChannelPortTester();
    final resultPort = ResultPort(portTester.sendPort);

    resultPort.ok(123);
    final result = await portTester.result;
    expect(result, isA<OK<int>>());

    expect((result as OK<int>).value, 123);
  });

  test('err', () async {
    final portTester = ChannelPortTester();
    final resultPort = ResultPort(portTester.sendPort);

    resultPort.err(StateError('error'), StackTrace.current);
    final result = await portTester.result;
    expect(result, isA<Err>());
  });
}

void testMethodPort() {
  test('invokeMethod', () async {
    final portTester = ChannelPortTester();
    final methodPort = MethodPort(portTester.sendPort);

    methodPort.invokeMethod(const CloseMethod());
    final result = await portTester.result;
    expect(result, isA<MethodConfiguration>());

    expect((result as MethodConfiguration).method, isA<CloseMethod>());
  });
}
