import 'dart:isolate';

import 'package:test/test.dart';
import 'package:isolate_executor/isolate_executor.dart';

void main(List<String> args) async {
  final isolateExecutor = await IsolateExecutor.spawn();
  print('Isolate ${Isolate.current.hashCode}');
  var foo = 'foo';
  await isolateExecutor.execute(() {
    print('1 $foo Isolate ${Isolate.current.hashCode}');
  });
  isolateExecutor.execute(() {
    print('2 $foo Isolate ${Isolate.current.hashCode}');
  });
  isolateExecutor.execute<void>(() {
    print('3 $foo Isolate ${Isolate.current.hashCode}');
  });
  isolateExecutor.execute(() {
    print('4 $foo Isolate ${Isolate.current.hashCode}');
    return '我是返回值';
  }).then((value) => print(value));
}
