### A wrapper around Isolate

## Usage
```dart
import 'package:isolate_runner/isolate_runner.dart';

void main() async {
  final isolateRunner = IsolateRunner();

  await isolateRunner.run(() {
    print('Hello Isolate!');
  });
  await isolateRunner.runWithArgs(test, 100);
  await isolateRunner.close();
}

void test(int value) {
  print(value);
}
```