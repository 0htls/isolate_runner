### A wrapper around Isolate

## Usage
```dart
import 'package:isolate_executor/isolate_executor.dart';

void main() async {
  final isolateExecutor = IsolateExecutor();

  await isolateExecutor.execute(() {
    print('Hello Isolate!');
  });
  await isolateExecutor.executeWithArgs(test, 100);
  await isolateExecutor.close();
}

void test(int value) {
  print(value);
}
```