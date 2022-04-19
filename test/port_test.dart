import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';

import 'package:isolate_runner/src/ports.dart';
import 'package:isolate_runner/src/channel.dart' show MethodConfiguration;
import 'package:isolate_runner/src/methods.dart';

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
  test('ResultPort.success', () async {
    final portTester = ChannelPortTester();
    final resultPort = ResultPort<int>(portTester.sendPort);

    resultPort.success(123);
    final result = await portTester.result;
    expect(result, isA<MethodResult<int>>());

    expect((result as MethodResult<int>).value, 123);
  });

  test('ResultPort.error', () async {
    final portTester = ChannelPortTester();
    final resultPort = ResultPort(portTester.sendPort);

    resultPort.error(StateError('error'), StackTrace.current);
    final result = await portTester.result;
    expect(result, isA<MethodResult>());
  });
}

void testMethodPort() {
  test('sendMethodForResult', () async {
    final portTester = ChannelPortTester();
    final methodPort = MethodPort(portTester.sendPort);

    methodPort.sendMethodForResult(const Close());
    final result = await portTester.result;
    expect(result, isA<MethodConfiguration>());

    expect((result as MethodConfiguration).method, isA<Close>());
  });
}
