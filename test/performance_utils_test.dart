import 'package:flutter_test/flutter_test.dart';

import 'package:budgie/presentation/utils/performance_utils.dart';

void main() {
  test('Debouncer runs only the latest callback', () async {
    final debouncer = Debouncer(const Duration(milliseconds: 10));
    var calls = 0;

    debouncer.run(() => calls++);
    debouncer.run(() => calls++);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    debouncer.dispose();

    expect(calls, 1);
  });
}
